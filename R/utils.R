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
    plot_encoded = plot_to_base64(plot)
  )
}

plot_to_base64 <- function(plot, ...) {
  plot_file <- tempfile(fileext = ".png")
  on.exit(if (plot_file != "" && file.exists(plot_file)) unlink(plot_file))

  png(plot_file, ...)
  tryCatch(
    {print(plot)},
    finally = {
      dev.off()
    }
  )
  
  base64enc::base64encode(plot_file)
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
