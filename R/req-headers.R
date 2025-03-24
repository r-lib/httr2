#' Modify request headers
#'
#' @description
#' `req_headers()` allows you to set the value of any header.
#'
#' `req_headers_redacted()` is a variation that adds "redacted" headers, which
#' httr2 avoids printing on the console. This is good practice for
#' authentication headers to avoid accidentally leaking them in log files.
#'
#' @param .req A [request].
#' @param ... <[`dynamic-dots`][rlang::dyn-dots]> Name-value pairs of headers
#'   and their values.
#'
#'   * Use `NULL` to reset a value to httr2's default.
#'   * Use `""` to remove a header.
#'   * Use a character vector to repeat a header.
#' @param .redact A character vector of headers to redact. The Authorization
#'   header is always redacted.
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
#'   req_headers(!!!headers, HeaderThree = "three") |>
#'   req_dry_run()
#'
#' # Use `req_headers_redacted()`` to hide a header in the output
#' req_secret <- req |>
#'   req_headers_redacted(Secret = "this-is-private") |>
#'   req_headers(Public = "but-this-is-not")
#'
#' req_secret
#' req_secret |> req_dry_run()
req_headers <- function(.req, ..., .redact = NULL) {
  check_request(.req)
  check_character(.redact, allow_null = TRUE)
  check_header_values(...)

  headers  <- modify_list(.req$headers, ..., .ignore_case = TRUE)

  redact <- union(.redact, "Authorization")
  redact <- redact[tolower(redact) %in% tolower(names(headers))]
  redact <- sort(union(redact, attr(.req$headers, "redact")))

  .req$headers <- new_headers(headers, redact)

  .req
}

#' @export
#' @rdname req_headers
req_headers_redacted <- function(.req, ...) {
  check_request(.req)

  headers <- list2(...)
  req_headers(.req, !!!headers, .redact = names(headers))
}

check_header_values <- function(..., error_call = caller_env()) {
  dots <- list2(...)
  
  type_ok <- map_lgl(dots, function(x) is_atomic(x) || is.null(x))
  if (any(!type_ok)) {
    cli::cli_abort(
      "All elements of {.arg ...} must be either an atomic vector or NULL.",
      call = error_call
    )
  }

  invisible()
}
