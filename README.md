
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
