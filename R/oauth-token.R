#' Create an OAuth token
#'
#' Creates a S3 object of class `<httr2_token>` representing an OAuth token
#' returned from the access token endpoint.
#'
#' @param access_token The access token used to authenticate request
#' @param token_type Type of token; only `"bearer"` is currently supported.
#' @param expires_in Number of seconds until token expires.
#' @param refresh_token Optional refresh token; if supplied, this can be
#'   used to cheaply get a new access token when this one expires.
#' @param ... Additional components returned by the endpoint
#' @param .date Date the request was made; used to convert the relative
#'   `expires_in` to an absolute `expires_at`.
#' @return An OAuth token: an S3 list with class `httr2_token`.
#' @export
#' @examples
#' oauth_token("abcdef")
#' oauth_token("abcdef", expires_in = Sys.time() + 3600)
#' oauth_token("abcdef", refresh_token = "ghijkl")
oauth_token <- function(
                        access_token,
                        token_type = "bearer",
                        expires_in = NULL,
                        refresh_token = NULL,
                        ...,
                        .date = Sys.time()
                        ) {

  check_string(access_token, "`access_token`")
  check_string(token_type, "`token_type`")
  # TODO: should tokens always store their scope?

  if (!is.null(expires_in)) {
    # Store as unix time to avoid worrying about type coercions in cache
    expires_at <- as.numeric(.date) + expires_in
  } else {
    expires_at <- NULL
  }

  structure(
    compact(list2(
      token_type = token_type,
      access_token = access_token,
      expires_at = expires_at,
      refresh_token = refresh_token,
      ...
    )),
    class = "httr2_token"
  )
}

#' @export
print.httr2_token <- function(x, ...) {
  cli::cli_text(cli::style_bold("<", paste(class(x), collapse = "/"), ">"))
  redacted <- list_redact(x, c("access_token", "refresh_token"))
  if (has_name(redacted, "expires_at")) {
    redacted$expires_at <- format(.POSIXct(x$expires_at))
  }

  # https://github.com/r-lib/cli/issues/347
  is_empty <- map_lgl(redacted, ~ .x == "")
  redacted[is_empty] <- "''"

  cli::cli_dl(compact(redacted))

  invisible(x)
}

token_has_expired <- function(token, delay = 5) {
  if (is.null(token$expires_at)) {
    FALSE
  } else {
    (unix_time() + delay) > token$expires_at
  }
}

token_refresh <- function(client, refresh_token, scope = NULL, token_params = list()) {
  oauth_client_get_token(client,
    grant_type = "refresh_token",
    refresh_token = refresh_token,
    scope = scope,
    !!!token_params
  )
}
