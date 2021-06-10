
<!-- README.md is generated from README.Rmd. Please edit that file -->

# httr2

<!-- badges: start -->

[![R-CMD-check](https://github.com/r-lib/httr2/workflows/R-CMD-check/badge.svg)](https://github.com/r-lib/httr2/actions)
[![Codecov test
coverage](https://codecov.io/gh/r-lib/httr2/branch/master/graph/badge.svg)](https://codecov.io/gh/r-lib/httr2?branch=master)
<!-- badges: end -->

httr2 is a ground up rewrite of httr with two main goals:

-   Create a pipeable API that makes the request object explicit.

-   Solve problems that were out of scope for httr but make writing API
    wrappers a pain (e.g. rate-limiting, retries, non-standard oauth, …)

## Major differences to httr

-   HTTP errors are automatically converted into R errors. Use
    `req_error()` to override the defaults (which turn all 4xx and 5xx
    responses into errors), or to extract additional information about
    the error from the body of the response.

-   It’s easy to automatically retry if the request fails or encounters
    a transient HTTP error (e.g. a 429 rate limit request). Use
    `req_retry()` to define maximum number of retries, and override the
    defaults that determine which errors are transient, and how long to
    wait before retrying.

## Installation

You can install the released version of httr2 from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("httr2")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("r-lib/httr2")
```

## Acknowledgements

httr2 wouldn’t be possible without
[curl](https://jeroen.cran.dev/curl/),
[openssl](https://github.com/jeroen/openssl/),
[jsonlite](https://jeroen.cran.dev/jsonlite/), and
[jose](https://github.com/jeroen/jose/), which are all maintained by
[Jeroen Ooms](https://github.com/jeroen). A big thanks also go to [Jenny
Bryan](https://jennybryan.org) and [Craig
Citro](https://research.google/people/CraigCitro/) who have given me
much useful feedback on the both design of the internals and the user
facing API.
