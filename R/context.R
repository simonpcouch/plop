# context is rstudioapi::getActiveDocumentContext() or friends
fetch_code_context <- function(context) {
  contents <- context$contents
  selection <- context$selection

  end_before <- selection[[1]]$range$start[1] - 1
  start_after <- min(selection[[1]]$range$end[1] + 1, length(contents))

  before <- contents[seq_len(end_before)]
  after <- contents[seq(start_after, length(contents))]
  list(
    contextBefore = before, 
    currentSelection = 
      contents[seq(selection[[1]]$range$start[1], selection[[1]]$range$end[1])]
  )
}

xml_tag <- function(x, name) {
  check_string(name)
  if (length(x) == 0 || identical(x, "")) {
    return(character(0))
  } else {
    paste0(
      paste0("{", name, "}\n", collapse = ""), 
      paste0(unlist(x), collapse = "\n"), 
      paste0("\n{/", name, "}", collapse = ""),
      collapse = "\n"
    )
  }
}

fetch_env_context <- function(selection, env = global_env()) {
  # split the selection up into "words", e.g.
  # `ggplot(stackoverflow) + aes(x = Salary)` ->
  # `c("ggplot", "stackoverflow", "aes", "x", "Salary")`.
  # we're fine with this result being a superset of what we'd actually
  # find to be meaningful symbols, as we ultimately just supply context
  # on results that also appear in `names(env)`.
  words <- unlist(regmatches(
    selection,
    gregexpr("\\b[A-Za-z][A-Za-z0-9._]*\\b", selection)
  ))

  btw::btw_this(env, items = words[words %in% names(env)])
}
