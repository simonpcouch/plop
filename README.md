
<!-- README.md is generated from README.Rmd. Please edit that file -->

# plop

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/plop)](https://CRAN.R-project.org/package=plop)
<!-- badges: end -->

plop is a proof-of-concept ggplot2 assistant. The package’s addin
launches a Shiny app that does the following:

1)  Given some code selection from your editor, generates bare-bones
    plotting boilerplate
2)  Runs the plotting code
3)  Makes 4 suggestions on how to improve the plot
4)  Once a suggestion has been submitted, generates new plotting code
5)  Iterates on steps 2-4

Once you’re satisfied with the resulting code, click “Apply” to
integrate the lines back into your file.

## Installation

You can install the development version of plop like so:

``` r
pak::pak("simonpcouch/plop")
```

# Example

<img src="https://github.com/user-attachments/assets/2e2abf2f-926d-4efa-99b0-6e23723039dc" alt="A screencast of a Positron session. A script called example.R is open in the editor with some minimal ggplot2 lines, one of which will cause an error. I highlight the plotting lines and then press a keyboard shortcut to boot up a shiny app. The app runs the code, presents the image, and then makes suggestions to improve it based on the presented image. When I'm satisfied with the plot, I click 'Apply' to add the lines to my source file." width="100%" />
