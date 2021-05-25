#' Set request headers
#'
#' `req_headers()` allows you to set the value of any header.
#'
#' @param .req A [req]uest.
#' @param ... Name-value pairs of headers and their values. Note that setting a
#'    header to `NULL` will not necessarily remove it, but will reset it
#'    to httr2's default value. To remove a header, set it to `""`.
#' @export
#' @examples
#' req <- req("http://example.com")
#' # Setting Accept to NULL uses curl's default:
#' req %>%
#'   req_headers(Accept = NULL) %>%
#'   req_dry_run()
#'
#' # Setting it to "" removes it:
#' req %>%
#'   req_headers(Accept = "") %>%
#'   req_dry_run()
req_headers <- function(.req, ...) {
  .req$headers <- modify_list(.req$headers, ...)
  .req
}
