#' Interactively create and improve ggplot2 plots
#'
#' @param context Information on the active RStudio document, typically from 
#' `rstudioapi::getActiveDocumentContext()`. Optional.
#'
#' @returns 
#' Launches a shiny app that does the following:
#' 
#' 1) Given some code selection, suggests bare-bones plotting boilerplate
#' 2) Runs the plotting code
#' 3) Makes 4 suggestions on how to improve the plot
#' 4) Once a suggestion has been submitted, generates new plotting code.
#' 5) Iterate on steps 2-4.
#' 
#' Once you're satisfied with the resulting code, click "Apply" to integrate
#' the lines back into your file.
#'
#' @export
plop <- function(context = rstudioapi::getActiveDocumentContext()) {
  force(context)
  
  ui <- page_fillable(
    theme = bs_theme(),
    html_deps(),
    layout_columns(
      card(
        card_header("Suggestions"),
        chat_ui("chat", placeholder = "Or add a free-form suggestion...")
      ),
      layout_columns(row_heights = c(3, 1, 1), card(
        card_header("Plot"),
        card_body(
          plotOutput("plot", height = "400px")
        ),
        verbatimTextOutput("plot_code"),
        div(
          style = "display: flex; justify-content: flex-end; padding: 10px;",
          actionButton("apply_btn", "Apply"),
          actionButton("quit_btn", "Quit")
        )
      ))
    )
  )
  
  server <- function(input,
                     output,
                     session) {
    plot_env <- env_clone(global_env())
    
    # Use reactiveValues to store state
    rv <- reactiveValues(
      current_plot_code = NULL,
      plot_obj = NULL,
      plot_encoded = NULL
    )
    
    # main two server actions -------------------------------------------------
    # Given some plotting code and a plain-language instruction on how to change
    # it, update the plotting code and run it
    iterate_on_plot <- function(current_plot_code, instruction) {
      plot_prompt <- assemble_plot_turn(
        env_context = btw::btw(globalenv(), clipboard = FALSE),
        instruction = instruction,
        current_plot_code = current_plot_code
      )
      
      plot_client <- plot_client()
      new_plot_code <- plot_client$chat(plot_prompt, echo = FALSE)
      
      rv$current_plot_code <- new_plot_code
      output$plot_code <- renderPrint({cat(new_plot_code)})
      .last_plot_client <<- plot_client
      
      results <- evaluate_plot_code(new_plot_code, env = plot_env)
      rv$plot_obj <- results$plot_obj
      rv$plot_encoded <- results$plot_encoded
      
      results$current_plot_code <- new_plot_code
      
      return(results)
    }
    
    # Given some plotting code and the plot itself in B64, make 
    # 4 plain-language suggestions on how to improve it
    suggest_from_plot <- function(context, current_plot_code, plot_encoded) {
      new_suggestions_prompt <- assemble_suggestions_turn(
        code_context = list(
          contextBefore = fetch_code_context(context)$contextBefore,
          currentSelection = current_plot_code
        ),
        env_context = btw::btw(globalenv(), clipboard = FALSE)
      )
      
      suggestions_client <- suggestions_client()
      suggestions_stream <- suggestions_client$stream_async(
        new_suggestions_prompt,
        plot_encoded
      )
      chat_append("chat", suggestions_stream, role = "assistant")
      .last_suggestions_client <<- suggestions_client
    }
    
    output$plot <- renderPlot({
      req(rv$plot_obj)
      rv$plot_obj
    })

    # main server logic -------------------------------------------------------
    # The first time around, assume that if the user highlighted something,
    # they'd like it to be plotted. Allow a model to generate the first round
    # of plotting code.
    observeEvent(TRUE, {
      initial_selection <- context$selection[[1]]$text
      if (nchar(initial_selection) > 0) {
        initial_code <- initial_client()$chat(initial_selection)
        rv$current_plot_code <- initial_code
        
        output$plot_code <- renderPrint({cat(initial_code)})
        
        results <- evaluate_plot_code(initial_code, env = plot_env)
        rv$plot_obj <- results$plot_obj
        rv$plot_encoded <- results$plot_encoded
        
        current_code <- initial_code
        plot_enc <- results$plot_encoded
        
        # Generate suggestions only after plot is displayed
        session$onFlushed(function() {
          suggest_from_plot(
            context = context, 
            current_plot_code = current_code, 
            plot_encoded = plot_enc
          )
        })
      }
    }, once = TRUE)
    
    # When the user submits an instruction:
    # 1) Prompt a model for plotting code
    # 2) Run the plotting code and display it to the user
    # 3) Submit the new plotting code and plot to a model to generate new
    #    suggestions
    observeEvent(input$chat_user_input, {
      current_code <- isolate(rv$current_plot_code)
      
      results <- iterate_on_plot(
        current_plot_code = current_code,
        instruction = input$chat_user_input
      )
      
      # Store values in regular variables for the callback
      updated_code <- isolate(rv$current_plot_code)
      plot_enc <- isolate(rv$plot_encoded)
      
      # Then schedule suggestions to run after UI updates
      session$onFlushed(function() {
        suggest_from_plot(
          context = context,
          current_plot_code = updated_code, 
          plot_encoded = plot_enc
        )
      })
    })

    observeEvent(input$apply_btn, {
      rstudioapi::modifyRange(
        location = context$selection[[1]]$range,
        text = rv$current_plot_code
      )
      
      session$onSessionEnded(stopApp())
      session$close()
    })
    
    observeEvent(input$quit_btn, {
      session$onSessionEnded(stopApp())
      session$close()
    })
  }
  
  shinyApp(ui, server)
}

# prompt helpers ---------------------------------------------------------------
assemble_suggestions_turn <- function(
    code_context,
    env_context = btw::btw(global_env(), clipboard = FALSE)
) {
  paste0(
    c(
      xml_tag(code_context$contextBefore, "contextBefore"),
      xml_tag(code_context$currentSelection, "currentSelection"),
      xml_tag(env_context, "envContext")
    ),
    collapse = "\n\n"
  )
}

assemble_plot_turn <- function(
  env_context = btw::btw(global_env(), clipboard = FALSE),
  instruction,
  current_plot_code
) {
  paste0(
    c(
      xml_tag(current_plot_code, "currentCode"),
      xml_tag(env_context, "envContext"),
      xml_tag(instruction, "instruction")
    ),
    collapse = "\n\n"
  )
}

# clients (ellmer Chat objects) ------------------------------------------------
suggestions_client <- function() {
  chat_claude(
    model = "claude-3-7-sonnet-latest",
    system_prompt = readLines(
      system.file("prompt-suggestions.md", package = "plop")
    )
  )
}

plot_client <- function() {
  chat_claude(
    model = "claude-3-7-sonnet-latest",
    system_prompt = readLines(
      system.file("prompt-plot.md", package = "plop")
    )
  )
}

initial_client <- function() {
  chat_claude(
    model = "claude-3-7-sonnet-latest",
    system_prompt = readLines(
      system.file("prompt-initial.md", package = "plop")
    )
  )
}
