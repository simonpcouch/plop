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
