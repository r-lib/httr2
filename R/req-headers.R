#' Modify request headers
#'
#' `req_headers()` allows you to set the value of any header. Use
#' `req_headers_redacted()` to add "redacted" headers which httr2 strives
#' to avoid printing to the console. This is good practice for headers used
#' for authentication to avoid accidentally including them in log files.
#'
#' @param .req A [request].
#' @param ... <[`dynamic-dots`][rlang::dyn-dots]> Name-value pairs of headers
#'   and their values.
#'
#'   * Use `NULL` to reset a value to httr2's default
#'   * Use `""` to remove a header
#'   * Use a character vector to repeat a header.
#' @param .redact Headers to redact. If `NULL`, the default, the added headers
#'   are not redacted.
#' @returns A modified HTTP [request].
#' @export
#' @examples
#' req <- request("http://example.com")
#'
#' # Use req_headers() to add arbitrary additional headers to the request
#' req |>
#'   req_headers(MyHeader = "MyValue") |>
#'   req_dry_run()
#'
#' # Repeated use overrides the previous value:
#' req |>
#'   req_headers(MyHeader = "Old value") |>
#'   req_headers(MyHeader = "New value") |>
#'   req_dry_run()
#'
#' # Setting Accept to NULL uses curl's default:
#' req |>
#'   req_headers(Accept = NULL) |>
#'   req_dry_run()
#'
#' # Setting it to "" removes it:
#' req |>
#'   req_headers(Accept = "") |>
#'   req_dry_run()
#'
#' # If you need to repeat a header, provide a vector of values
#' # (this is rarely needed, but is important in a handful of cases)
#' req |>
#'   req_headers(HeaderName = c("Value 1", "Value 2", "Value 3")) |>
#'   req_dry_run()
#'
#' # If you have headers in a list, use !!!
#' headers <- list(HeaderOne = "one", HeaderTwo = "two")
#' req |>
#'    req_headers(!!!headers, HeaderThree = "three") |>
#'    req_dry_run()
#'
#' # Use `.redact` to hide a header in the output
#' req |>
#'   req_headers_redacted(Secret = "this-is-private") |>
#'   req_headers(Public = "but-this-is-not") |>
#'   req_dry_run()
req_headers <- function(.req, ..., .redact = NULL) {
  check_request(.req)

  headers <- list2(...)
  header_names <- names2(headers)
  check_character(.redact, allow_null = TRUE)

  redact_out <- attr(.req$headers, "redact") %||% .redact %||% character()
  redact_out <- union(redact_out, .redact)
  .req$headers <- modify_list(.req$headers, !!!headers)

  attr(.req$headers, "redact") <- redact_out

  .req
}

#' @export
#' @rdname req_headers
req_headers_redacted <- function(.req, ...) {
  check_request(.req)

  dots <- list(...)
  req_headers(.req, !!!dots, .redact = names(dots))
}
