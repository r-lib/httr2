
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

  # force all arguments
  list(header_req, header_resp, body_req, body_resp, info, redact_headers)

  debug <- function(type, msg) {
    # Set in req_prepare()
    headers <- req$state$headers
    to_redact <- attr(headers, "redact")

    switch(verbose_enum(type),
      text =       if (info)        verbose_message("*  ", msg),
      header_in =  if (header_resp) verbose_header("<- ", msg),
      header_out = if (header_req)  verbose_header("-> ", msg, redact_headers, to_redact = to_redact),
      data_in =    NULL, # displayed in handle_resp()
      data_out =   if (body_req)    verbose_body(">> ", msg, headers$`content-type`)
    )
  }
  req <- req_options(req, debugfunction = debug, verbose = TRUE)
  req <- req_policies(req, show_body = body_resp)
  req
}

verbose_enum <- function(i) {
  if (i < 0 || i > 6) {
    cli::cli_warn("Unknown verbosity level {i}")
  }

  switch(i + 1,
    "text",
    "header_in",
    "header_out",
    "data_in",
    "data_out",
    "ssl_data_in",
    "ssl_data_out"
  )
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

verbose_body <- function(prefix, x, content_type) {
  show_body(
    x,
    content_type,
    prefix = prefix,
    pretty_json = getOption("httr2_pretty_json", TRUE)
  )
}

verbose_header <- function(prefix, x, redact = TRUE, to_redact = NULL) {
  x <- readBin(x, character())
  lines <- unlist(strsplit(x, "\r?\n", useBytes = TRUE))

  for (line in lines) {
    if (grepl("^[-a-zA-z0-9]+:", line)) {
      header <- headers_redact(as_headers(line, to_redact), redact)
      cli::cat_line(prefix, cli::style_bold(names(header)), ": ", format(header[[1]]))
    } else {
      cli::cat_line(prefix, line)
    }
  }
}

# Testing helpers -------------------------------------------------------------

req_verbose_test <- function(req) {
  # Reset all headers that otherwise might vary
  req <- req_headers(
    req,
    `Accept-Encoding` = "",
    Accept = "",
    Host = "http://example.com",
    `User-Agent` = ""
  )
  req <- req_options(req, forbid_reuse = TRUE)
  req
}

transform_verbose_response <- function(lines) {
  lines <- gsub(example_url(), "<webfakes>/", lines, fixed = TRUE)
  lines <- lines[!grepl("^<- (Date|ETag|Content-Length):", lines)]
  lines <- lines[!grepl("\\*  Closing connection", lines)]
  lines
}
