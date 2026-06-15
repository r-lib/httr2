#' Discover OAuth server metadata
#'
#' @description
#' `oauth_server_metadata()` fetches and parses an OAuth 2.0 Authorization
#' Server Metadata document (`r rfc(8414)`) or OpenID Connect Discovery
#' document, returning the endpoints advertised by an issuer. Use it to
#' discover values like `authorization_endpoint`, `token_endpoint`, and
#' `device_authorization_endpoint` rather than hard-coding them:
#'
#' ```r
#' meta <- oauth_server_metadata("https://accounts.google.com")
#' client <- oauth_client("id", token_url = meta$token_endpoint, secret = "...")
#' oauth_flow_auth_code(client, auth_url = meta$authorization_endpoint)
#' ```
#'
#' As a security measure, the `issuer` reported in the returned document is
#' validated against the requested `issuer` (`r rfc(8414, "3.3")`); a mismatch
#' is an error. This check is skipped when `url` is supplied without `issuer`.
#'
#' @param issuer The issuer URL, e.g. `"https://accounts.google.com"`. The
#'   metadata URL is derived from it according to `type`.
#' @param type Which well-known suffix to use when `url` is not supplied:
#'
#'   * `"openid"` (the default) appends `/.well-known/openid-configuration`,
#'     the form served by essentially every major provider. Despite the name,
#'     it is a superset that also advertises the OAuth endpoints, so it is the
#'     better default even for plain OAuth.
#'   * `"oauth"` inserts `/.well-known/oauth-authorization-server` between the
#'     origin and any path, as defined in `r rfc(8414)`. Use this for the few
#'     providers that serve only the OAuth document.
#' @param url Optionally, the full metadata document URL. Use this as an escape
#'   hatch for providers that follow neither well-known convention. When
#'   supplied, `issuer` is only used for validation and can be omitted.
#' @returns An S3 list with class `httr2_oauth_server_metadata` containing the
#'   full parsed metadata document. Endpoints that the provider does not
#'   advertise are simply absent.
#' @export
#' @family OAuth flows
#' @examplesIf is_online()
#' oauth_server_metadata("https://accounts.google.com")
oauth_server_metadata <- function(
  issuer,
  type = c("openid", "oauth"),
  url = NULL
) {
  type <- arg_match(type)
  check_string(url, allow_null = TRUE)

  if (missing(issuer)) {
    if (is.null(url)) {
      cli::cli_abort("Must supply either {.arg issuer} or {.arg url}.")
    }
    issuer <- NULL
  } else {
    check_string(issuer)
  }

  url <- url %||% oauth_metadata_url(issuer, type)

  metadata <- request(url) |>
    req_perform() |>
    resp_body_json(simplifyVector = TRUE, simplifyDataFrame = FALSE)

  # https://datatracker.ietf.org/doc/html/rfc8414#section-3.3
  if (!is.null(issuer) && !identical(metadata$issuer, issuer)) {
    cli::cli_abort(c(
      "Metadata {.field issuer} doesn't match the requested {.arg issuer}.",
      "*" = "Requested {.str {issuer}}.",
      "*" = "Received {.str {metadata$issuer}}."
    ))
  }

  structure(metadata, class = "httr2_oauth_server_metadata")
}

# OIDC appends the suffix to the issuer; RFC 8414 inserts it between the origin
# and any path. These differ precisely for multi-tenant, path-carrying issuers.
oauth_metadata_url <- function(issuer, type) {
  parsed <- url_parse(issuer)
  path <- sub("/$", "", parsed$path)

  parsed$path <- switch(
    type,
    openid = paste0(path, "/.well-known/openid-configuration"),
    oauth = paste0("/.well-known/oauth-authorization-server", path)
  )
  url_build(parsed)
}

#' @export
print.httr2_oauth_server_metadata <- function(x, ...) {
  cli::cat_line(cli::style_bold("<", paste(class(x), collapse = "/"), ">"))

  # Show the issuer and endpoint URLs; the remaining fields (capability arrays,
  # flags, and other metadata) are reference data, so just count them.
  x <- compact(x)
  is_url <- map_lgl(x, \(val) is_string(val) && grepl("^https?://", val))
  bullets(x[is_url])

  n_extra <- sum(!is_url)
  if (n_extra > 0) {
    cli::cat_line(cli::format_inline("* and {n_extra} more field{?s}."))
  }
  invisible(x)
}
