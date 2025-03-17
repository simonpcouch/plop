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
      card(
        card_header("Plot"),
        card_body(
          plotOutput("plot", height = "400px"),
          div(
            style = "display: flex; justify-content: space-between; padding-top: 10px;",
            accordion(
              accordion_panel(
                "Plot Code",
                verbatimTextOutput("plot_code"),
                value = "plot_code_panel"
              ),
              open = FALSE,
              id = "code_accordion"
            ),
            div(
              style = "display: flex; gap: 10px;",
              actionButton("apply_btn", "Apply"),
              actionButton("quit_btn", "Quit")
            )
          )
        )
      )
    )
  )
  
  server <- function(input,
                     output,
                     session) {
    plot_env <- env_clone(global_env())
    client <- client()
    
    # Use reactiveValues to store state
    rv <- reactiveValues(
      current_plot_code = NULL,
      plot_obj = NULL,
      plot_encoded = NULL
    )
    
    # main server action: generate plots ---------------------------------------
    # takes plotting code and
    # * displays it in the UI
    # * runs the code to generate the plot
    # * displays the plot in the UI
    # * asks the model for suggestions based on it
    generate_plot <- function(code, ...) {
      rv$current_plot_code <- code
      output$plot_code <- renderPrint({cat(code)})

      results <- evaluate_plot_code(code, env = plot_env)
      rv$plot_obj <- results$plot_obj
      rv$plot_encoded <- results$plot_encoded
      
      output$plot <- renderPlot({
        req(rv$plot_obj)
        rv$plot_obj
      })

      results$plot_encoded
    }

    generate_plot_impl <- function(code, ...) {
      # a la https://github.com/tidyverse/ellmer/pull/231
      # tool calls results have to be a list like below, while `$chat()`
      # and friends require the `<content>` objects.
      results <- generate_plot(code, ...)

      I(list(list(
        type = "image",
        source = list(
          type = "base64",
          media_type = results@type,
          data = results@data
        )
      )))
    }

    generate_plot_tool <- 
      tool(
        generate_plot_impl,
        "Given some ggplot2 plotting code, shows the plotting code to the user,
         generates the plot by running the code, displays the plot to the user,
         ultimately returns the plot, encoded as base64",
        code = type_string(
          "Valid ggplot2 plotting code."
        )
      )
    
    client$register_tool(generate_plot_tool)
    
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
        
        results <- generate_plot(
          initial_code,
          assemble_context(
            code_context = fetch_code_context(context),
            env_context = fetch_env_context(context$selection[[1]]$text)
          )
        )

        rv$plot_encoded <- results@data

        stream <- client$stream_async(
          assemble_context(
            code_context = fetch_code_context(context),
            env_context = fetch_env_context(context$selection[[1]]$text)
          ),
          results
        )
        chat_append("chat", stream)
        .stash_last_plop(client)
      }
    }, once = TRUE)
    
    observeEvent(input$chat_user_input, {
      stream <- client$stream_async(input$chat_user_input)
      chat_append("chat", stream)
      .stash_last_plop(client)
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
assemble_context <- function(
    code_context,
    env_context
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

# clients (ellmer Chat objects) ------------------------------------------------
client <- function() {
  chat_claude(
    model = "claude-3-7-sonnet-latest",
    system_prompt = readLines(
      system.file("prompt-iterate.md", package = "plop")
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

.stash_last_plop <- function(x) {
  if (!"pkg:plop" %in% search()) {
    do.call(
      "attach",
      list(new.env(), pos = length(search()), name = "pkg:plop")
    )
  }
  env <- as.environment("pkg:plop")
  env$.last_plop <- x
  invisible(NULL)
}
