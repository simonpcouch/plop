# ad-hoc check functions ------------------------------------------------------
check_inherits <- function(
  x,
  class,
  x_arg = caller_arg(x),
  call = caller_env()
) {
  if (!inherits(x, class)) {
    cli::cli_abort(
      "{.arg {x_arg}} must be a {.cls {class}}, not {.obj_type_friendly {x}}.",
      call = call
    )
  }

  invisible(NULL)
}

# running plotting code -------------------------------------------------------
evaluate_plot_code <- function(code, env) {
  plot <- eval(parse(text = code), envir = env)
  list(
    plot_obj = plot,
    plot_encoded = content_image_ggplot(plot)
  )
}

content_image_ggplot <- function(plot, ...) {
  plot_file <- withr::local_tempfile(fileext = ".png")

  suppressMessages(
    ggplot2::ggsave(plot_file, plot, device = "png")
  )
  
  content_image_file(plot_file)
}

# from databot ----------------------------------------------------------------
html_deps <- function() {
  htmltools::htmlDependency(
    "plop",
    packageVersion("plop"),
    src = "www",
    package = "plop",
    script = "script.js",
    stylesheet = "style.css"
  )
}

as_str <- function(..., collapse = "\n", sep = "") {
  # Collapse each character vector in ..., then concatenate
  lst <- rlang::list2(...)
  strings <- vapply(lst, paste, character(1), collapse = collapse)
  paste(strings, collapse = sep)
}
