#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @import R6
#' @import rlang
#' @importFrom glue glue
#' @importFrom lifecycle deprecated
## usethis namespace: end
NULL

the <- new_environment()
the$throttle <- list()
the$cache_throttle <- list()
the$token_cache <- new_environment()
the$last_response <- NULL
the$last_request <- NULL
the$last_pagination_request <- NULL
the$last_pagination_responses <- NULL
the$last_pagination_page <- NULL
the$last_pagination_n_pages <- NULL
the$last_pagination_max_pages <- NULL
