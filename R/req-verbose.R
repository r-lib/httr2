
#' Show extra output when request is performed
#'
#' @description
#' `req_verbose()` uses the following prefixes to distinguish between
#' different components of the HTTP requests and responses:
#'
#' * `* ` informative curl messages
#' * `->` request headers
#' * `>>` request body
#' * `<-` response headers
#' * `<<` response body
#'
#' @inheritParams req_perform
#' @param header_req,header_resp Show request/response headers?
#' @param body_req,body_resp Should request/response bodies? When the response
#'   body is compressed, this will show the number of bytes received in
#'   each "chunk".
#' @param info Show informational text from curl? This is mainly useful
#'   for debugging https and auth problems, so is disabled by default.
#' @param redact_headers Redact confidential data in the headers? Currently
#'   redacts the contents of the Authorization header to prevent you from
#'   accidentally leaking credentials when debugging/reprexing.
#' @seealso [req_perform()] which exposes a limited subset of these options
#'   through the `verbosity` argument and [with_verbosity()] which allows you
#'   to control the verbosity of requests deeper within the call stack.
#' @returns A modified HTTP [request].
#' @export
#' @examples
#' # Use `req_verbose()` to see the headers that are sent back and forth when
#' # making a request
#' resp <- request("https://httr2.r-lib.org") |>
#'   req_verbose() |>
#'   req_perform()
#'
#' # Or use one of the convenient shortcuts:
#' resp <- request("https://httr2.r-lib.org") |>
#'   req_perform(verbosity = 1)
req_verbose <- function(req,
                        header_req = TRUE,
                        header_resp = TRUE,
                        body_req = FALSE,
                        body_resp = FALSE,
                        info = FALSE,
                        redact_headers = TRUE) {
  check_request(req)

  to_redact <- attr(req$headers, "redact")
  debug <- function(type, msg) {
    switch(type + 1,
      text =       if (info)        verbose_message("*  ", msg),
      headerOut =  if (header_resp) verbose_header("<- ", msg),
      headerIn =   if (header_req)  verbose_header("-> ", msg, redact_headers, to_redact = to_redact),
      dataOut =    NULL, # displayed in handle_resp()
      dataIn =     if (body_req)    verbose_message(">> ", msg)
    )
  }
  req <- req_policies(req, show_body = body_resp)
  req <- req_options(req, debugfunction = debug, verbose = TRUE)
  req
}

# helpers -----------------------------------------------------------------

verbose_message <- function(prefix, x) {
  if (any(x > 128)) {
    # This doesn't handle unicode, but it seems like most output
    # will be compressed in some way, so displaying bodies is unlikely
    # to be useful anyway.
    lines <- paste0(length(x), " bytes of binary data")
  } else {
    x <- readBin(x, character())
    lines <- unlist(strsplit(x, "\r?\n", useBytes = TRUE))
  }
  cli::cat_line(prefix, lines)
}

verbose_header <- function(prefix, x, redact = TRUE, to_redact = NULL) {
  x <- readBin(x, character())
  lines <- unlist(strsplit(x, "\r?\n", useBytes = TRUE))

  for (line in lines) {
    if (grepl("^[-a-zA-z0-9]+:", line)) {
      header <- headers_redact(as_headers(line), redact, to_redact = to_redact)
      cli::cat_line(prefix, cli::style_bold(names(header)), ": ", header)
    } else {
      cli::cat_line(prefix, line)
    }
  }
}

# Testing helpers -------------------------------------------------------------

# Reset all headers that otherwise might vary
req_headers_reset <- function(req) {
  req_headers(
    req,
    `Accept-Encoding` = "",
    Accept = "",
    Host = "http://example.com",
    `User-Agent` = ""
  )
}

transform_resp_headers <- function(lines) {
  lines <- gsub(example_url(), "<webfakes>/", lines, fixed = TRUE)
  lines <- lines[!grepl("^<- (Date|ETag|Content-Length):", lines)]
  lines
}
