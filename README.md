
# Learn Bulgarian (Shiny App)

<!-- badges: start -->
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

The goal of LearnBulgarianShinyApp is to help you learn the basics of
the Bulgarian Language.

There is a “vocab” section to learn common words, and a “quiz” section
to test your knowledge.

## Quick Start

If working on a personal machine, you can install the development version of 
LearnBulgarianShinyApp like so:

``` r
remotes::install_github("dleng2242/LearnBulgarianShinyApp")
```

You can then launch the shiny app using:

``` r
LearnBulgarianShinyApp::run_app()
```

# Deployment

To deploy the app, first create the source tarball and docker file using the 
`{golem}` function:

```r 
golem::add_dockerfile_with_renv(output_dir = 'deploy')
```

This creates a directory called `deploy` that contains all the assets required 
for building the images. You can see mine is included in the repo. 

As the application image size can be several gigabytes, two dockerfiles are 
needed - one as a base Linux image with R installed, and a second image with 
the Shiny application installed on top. 

Please see the file `deploy/Build_Instructions.md` for further details and 
comprehensive instructions on how to build the local containers.
