#' Perform a dry run
#'
#' This shows you exactly what httr2 will send to the server, without
#' actually sending anything. It requires the httpuv package because it
#' works by sending the real HTTP request to a local webserver, thanks to
#' the magic of [curl::curl_echo()].
#'
#' ## Limitations
#'
#' * The HTTP version is always `HTTP/1.1` (since you can't determine what it
#'   will actually be without connecting to the real server).
#'
#' @inheritParams req_verbose
#' @param quiet If `TRUE` doesn't print anything.
#' @param testing_headers If `TRUE`, removes headers that httr2 would otherwise
#'   be automatically added, which are likely to change across test runs. This
#'   currently includes:
#'
#'   * The default `User-Agent`, which varies based on libcurl, curl, and
#'     httr2 versions.
#'   * The `Host`` header, which is often set to a testing server.
#'   * The `Content-Length` header, which will often vary by platform because
#'     of varying newline encodings. (And is also not correct if you have
#'     `pretty_json = TRUE`.)
#'   * The `Accept-Encoding` header, which varies based on how libcurl was
#'     built.
#' @param pretty_json If `TRUE`, automatically prettify JSON bodies.
#' @returns Invisibly, a list containing information about the request,
#'   including `method`, `path`, and `headers`.
#' @export
#' @examples
#' # httr2 adds default User-Agent, Accept, and Accept-Encoding headers
#' request("http://example.com") |> req_dry_run()
#'
#' # the Authorization header is automatically redacted to avoid leaking
#' # credentials on the console
#' req <- request("http://example.com") |> req_auth_basic("user", "password")
#' req |> req_dry_run()
#'
#' # if you need to see it, use redact_headers = FALSE
#' req |> req_dry_run(redact_headers = FALSE)
req_dry_run <- function(
  req,
  quiet = FALSE,
  redact_headers = TRUE,
  testing_headers = is_testing(),
  pretty_json = getOption("httr2_pretty_json", TRUE)
) {
  check_request(req)
  check_bool(quiet)
  check_bool(redact_headers)
  check_bool(testing_headers)
  check_installed("httpuv")

  if (testing_headers) {
    if (!req_has_user_agent(req)) {
      req <- req_headers(req, `user-agent` = "")
    }
    req <- req_headers(req, `accept-encoding` = "")
  }

  req <- req_prepare(req)
  handle <- req_handle(req)
  handle_preflight(req, handle)
  resp <- curl::curl_echo(handle, progress = FALSE)
  headers <- new_headers(
    as.list(resp$headers),
    redact = which_redacted(req$headers),
    lifespan = current_env()
  )

  if (!quiet) {
    cli::cat_line(resp$method, " ", resp$path, " HTTP/1.1")

    if (testing_headers) {
      # curl::curl_echo() overrides
      headers$host <- NULL
      headers$`content-length` <- NULL
    }
    show_headers(headers, redact = redact_headers)
    cli::cat_line()
    show_body(resp$body, headers$`content-type`, pretty_json = pretty_json)
  }

  invisible(list(
    method = resp$method,
    path = resp$path,
    body = resp$body,
    headers = headers_flatten(headers, redact = redact_headers)
  ))
}

show_body <- function(body, content_type, prefix = "", pretty_json = FALSE) {
  if (!is.raw(body)) {
    return(invisible())
  }

  if (is_text_type(content_type)) {
    body <- rawToChar(body)
    Encoding(body) <- "UTF-8"

    if (pretty_json && content_type == "application/json") {
      body <- pretty_json(body)
    }

    body <- gsub("\n", paste0("\n", prefix), body)
    cli::cat_line(prefix, body)
  } else {
    cli::cat_line(prefix, "<", length(body), " bytes>")
  }

  invisible()
}
