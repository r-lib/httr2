#' Modify request headers
#'
#' `req_headers()` allows you to set the value of any header.
#'
#' @param .req A [request].
#' @param ... <[`dynamic-dots`][rlang::dyn-dots]> Name-value pairs of headers
#'   and their values.
#'
#'   * Use `NULL` to reset a value to httr's default
#'   * Use `""` to remove a header
#'   * Use a character vector to repeat a header.
#' @param .redact If `TRUE`, all the added headers are redacted. Can also be a
#'   named list containing `TRUE` or `FALSE` declaring whether or not to redact
#'   a particular header. If a named list is provided, the default for any
#'   unspecified header is `TRUE`.
#' @returns A modified HTTP [request].
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
#'
#' # If you have headers in a list, use !!!
#' headers <- list(HeaderOne = "one", HeaderTwo = "two")
#' req %>%
#'    req_headers(!!!headers, HeaderThree = "three") %>%
#'    req_dry_run()
#'
req_headers <- function(.req, ..., .redact = FALSE) {
  check_request(.req)

  headers <- list2(...)
  header_names <- names2(headers)
  .redact <- unlist(check_list_of_bool(.redact, header_names))
  to_redact <- names(.redact)[.redact]
  to_unredact <- names(.redact)[!.redact]

  redact_out <- attr(.req$headers, "redact") %||% to_redact
  redact_out <- setdiff(redact_out, to_unredact)
  redact_out <- union(redact_out, to_redact)
  .req$headers <- modify_list(.req$headers, !!!headers)

  attr(.req$headers, "redact") <- redact_out

  .req
}

check_list_of_bool <- function(x, names, arg = caller_arg(x), call = caller_env()) {
  if (is_bool(x)) {
    rep_named(names, x)
  } else if (is_bare_list(x)) {
    check_unique_names(x, arg = arg, call = call)
    x[intersect(names(x), names)]
  } else  {
    cli::cli_abort(
      "{.arg {arg}} must be a list or a single `TRUE` or `FALSE`.",
      call = call
    )
  }
}

check_unique_names <- function(x, arg = caller_arg(x), call = caller_env()) {
  if (length(x) > 0L && !is_named(x)) {
    cli::cli_abort("All elements of {.arg {arg}} must be named.", call = call)
  }
  if (anyDuplicated(names(x))) {
    cli::cli_abort("The names of {.arg {arg}} must be unique.", call = call)
  }
}
