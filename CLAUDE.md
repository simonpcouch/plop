You are situated inside of an R package source directory. The subdirectory `R/` contains source files. The subdirectory `tests/testthat/` contains corresponding tests. e.g. `R/plop.R` is tested primarily in `tests/testthat/test-plop.R`.

Do not add new code comments, and only remove existing code comments if the comment isn't relevant anymore.

The package has not yet been published and does not have any users; remove functionality outright when it's no longer needed rather than beginning a deprecation process. No need to worry about breaking changes.

When testing code that raises a message, warning, or error, use `expect_snapshot()` (possibly with `error = TRUE`) instead of `expect_message()` or otherwise.

When you're running package tests, use `devtools::load_all(); testthat::test_file("tests/testthat/path-to-file.R")`. If you encounter namespacing issues, don't delete tests that otherwise should work, and instead ask me what to do.
