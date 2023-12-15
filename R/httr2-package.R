#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @import R6
#' @import rlang
#' @importFrom curl curl_version
#' @importFrom glue glue
#' @importFrom lifecycle deprecated
#' @importFrom utils packageVersion
## usethis namespace: end
NULL

the <- new_environment()
the$throttle <- list()
the$cache_throttle <- list()
the$token_cache <- new_environment()
the$last_response <- NULL
the$last_request <- NULL
