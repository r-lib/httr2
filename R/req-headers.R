#' Modify request headers
#'
#' `req_headers()` allows you to set the value of any header.
#'
#' @param .req A [request].
#' @param ... Name-value pairs of headers and their values.
#'
#'   * Use `NULL` to reset a value to httr's default
#'   * Use `""` to remove a header
#'   * Use a character vector to repeat a header.
#'
#' @export
#' @examples
#' req <- request("http://example.com")
#'
#' # Use req_headers() to add arbitrary additional headers to the request
#' req %>%
#'   req_headers(MyHeader = "MyValue") %>%
#'   req_dry_run()
#'
#' # Repeated use overrides the previous value:
#' req %>%
#'   req_headers(MyHeader = "Old value") %>%
#'   req_headers(MyHeader = "New value") %>%
#'   req_dry_run()
#'
#' # Setting Accept to NULL uses curl's default:
#' req %>%
#'   req_headers(Accept = NULL) %>%
#'   req_dry_run()
#'
#' # Setting it to "" removes it:
#' req %>%
#'   req_headers(Accept = "") %>%
#'   req_dry_run()
#'
#' # If you need to repeat a header, provide a vector of values
#' # (this is rarely needed, but is important in a handful of cases)
#' req %>%
#'   req_headers(HeaderName = c("Value 1", "Value 2", "Value 3")) %>%
#'   req_dry_run()
req_headers <- function(.req, ...) {
  check_request(.req)

  .req$headers <- modify_list(.req$headers, ...)
  .req
}
