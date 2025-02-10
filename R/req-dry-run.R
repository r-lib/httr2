#' Perform a dry run
#'
#' This shows you exactly what httr2 will send to the server, without
#' actually sending anything. It requires the httpuv package because it
#' works by sending the real HTTP request to a local webserver, thanks to
#' the magic of [curl::curl_echo()].
#'
#' ## Limitations
#'
#' * The `Host` header is not respected.
#'
#' @inheritParams req_verbose
#' @param quiet If `TRUE` doesn't print anything.
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
req_dry_run <- function(req, quiet = FALSE, redact_headers = TRUE) {
  check_request(req)
  check_installed("httpuv")

  req <- req_prepare(req)
  handle <- req_handle(req)
  curl::handle_setopt(handle, url = req$url)
  resp <- curl::curl_echo(handle, progress = FALSE)

  if (!quiet) {
    cli::cat_line(resp$method, " ", resp$path, " HTTP/1.1")

    headers <- headers_redact(
      as_headers(as.list(resp$headers)),
      redact = redact_headers,
      to_redact = attr(req$headers, "redact")
    )
    cli::cat_line(cli::style_bold(names(headers)), ": ", headers)
    cli::cat_line()
    show_body(resp$body, headers$`content-type`)
  }

  invisible(list(
    method = resp$method,
    path = resp$path,
    headers = as.list(resp$headers)
  ))
}

show_body <- function(body, content_type, prefix = "", prettify = FALSE) {
  if (!is.raw(body)) {
    return(invisible())
  }

  if (is_text_type(content_type)) {
    body <- rawToChar(body)
    Encoding(body) <- "UTF-8"

    if (prettify && content_type == "application/json") {
      body <- pretty_json(body)
    }

    body <- gsub("\n", paste0("\n", prefix), body)
    cli::cat_line(prefix, body)
  } else {
    cli::cat_line(prefix, "<", length(body), " bytes>")
  }

  invisible()
}
