#' Create an OAuth client
#'
#' An OAuth app is the combination of a client, a set of endpoints
#' (i.e. urls where various requests should be sent), and an authentication
#' mechanism. A client consists of at least a `client_id`, and also often
#' a `client_secret`. You'll get these values when you create the client on
#' the API's website.
#'
#' @param id Client identifier.
#' @param token_url Url to retrieve an access token.
#' @param secret Client secret. For most apps, this is technically confidential
#'   so in principle you should avoid storing it in source code. However, many
#'   APIs require it in order to provide a user friendly authentication
#'   experience, and the risks of including it are usually low. To make things
#'   a little safer, I recommend using [obfuscate()] when recorded the client
#'   secret in public code.
#' @param key Client key. As an alternative to using a `secret`, you can
#'   instead supply a confidential private key. This should never be included
#'   in a package.
#' @param auth Authentication mechanism used by the client to prove itself to
#'   the API. Can be one of three built-in methods ("body", "header", or "jwt"),
#'   or a function that will be called with arguments `req`, `client`, and
#'   the contents of `auth_params`.
#'
#'   The most common mechanism in the wild is `"body"` where the `client_id` and
#'   (optionally) `client_secret` are added to the body. `"header"` sends in
#'   `client_id` and `client_secret` in HTTP Authorization header. `"jwt_sig"`
#'   will generate a JWT, and include it in a `client_assertion` field in the
#'   body.
#'
#'   See [oauth_client_req_auth()] for more details.
#' @param auth_params Additional parameters passed to the function specified
#'   by `auth`.
#' @param name Optional name for the client. Used when generating cache
#'   directory. If `NULL`, generated from hash of `client_id`. If you're
#'   defining a package for use in a package, I recommend that you use
#'   the package name.
#' @export
oauth_client <- function(
                         id,
                         token_url,
                         secret = NULL,
                         key = NULL,
                         auth = c("body", "header", "jwt_sig"),
                         auth_params = list(),
                         name = hash(id)
                         ) {

  check_string(id, "`id`")
  check_string(token_url, "`token_url`")

  if (is.character(auth)) {
    if (missing(auth)) {
      auth <- if (is.null(key)) "body" else "jwt_sig"
    }
    auth <- arg_match(auth)

    if (auth == "header" && is.null(secret)) {
      abort("`auth = 'header' requires a `secret`")
    } else if (auth == "jwt_sig") {
      if (is.null(key)) {
        abort("`auth = 'jwt_sig' requires a `key`")
      }
      if (!has_name(auth_params, "claim")) {
        abort("`auth = 'jwt_sig' requires a claim specification in `auth_params`")
      }
    }

    auth <- paste0("oauth_client_req_auth_", auth)
  } else if (!is_function(auth)) {
    abort("`auth` must be a string or function")
  }

  structure(
    list(
      name = name,
      id = id,
      secret = secret,
      key = key,
      token_url = token_url,
      auth = auth,
      auth_params = auth_params
    ),
    class = "httr2_oauth_client"
  )
}

#' @export
print.httr2_oauth_client <- function(x, ...) {
  cli::cli_text(cli::style_bold("<", paste(class(x), collapse = "/"), ">"))
  redacted <- list_redact(compact(x), c("secret", "key"))
  cli::cli_dl(redacted)
  invisible(x)
}

#' OAuth client authentication
#'
#' @description
#' `oauth_client_req_auth()` authenticates a request using the authentication
#' strategy defined by the `auth` and `auth_param` arguments to [oauth_app()].
#' This used to authenticate the client as part of the OAuth flow, **not**
#' to authenticate a request on behalf of a user.
#'
#' There are three built-in strategies:
#'
#' * `oauth_client_req_body()` adds the client id and (optionally) the secret
#'    to the request body, as described in
#'   [rfc6749](https://datatracker.ietf.org/doc/html/rfc6749#section-2.3.1),
#'   Section 2.3.1.
#'
#' * `oauth_client_req_header()` adds the client id and secret using HTTP
#'   basic authentication with the `Authorization` header, as described in
#'   [rfc6749](https://datatracker.ietf.org/doc/html/rfc6749#section-2.3.1),
#'   Section 2.3.1.
#'
#' * `oauth_client_jwt_rs256()` adds a client assertion to the body using a
#'   JWT signed with `jwt_sign_rs256()` using a private key, as described in
#'   [rfc7523](https://datatracker.ietf.org/doc/html/rfc7523#section-2.2),
#'   Section 2.2.
#'
#' You will generally not call these functions directly but will instead
#' specify them through the `auth` argument to [oauth_client()]. The `req` and
#' `client` parameters are automatically filled in; other parameters come from
#' the `auth_params` argument.
#' @param req A [request].
#' @param client An [oauth_client].
oauth_client_req_auth <- function(req, client) {
  exec(client$auth, req = req, client = client, !!!client$auth_params)
}

#' @export
#' @rdname oauth_client_req_auth
oauth_client_req_auth_header <- function(req, client) {
  req_auth_basic(req,
    username = client$id,
    password = unobfuscate(client$secret, "client secret")
  )
}

#' @export
#' @rdname oauth_client_req_auth
oauth_client_req_auth_body <- function(req, client) {
  params <- compact(list(
    client_id = client$id,
    client_secret = unobfuscate(client$secret, "client secret") # might be NULL
  ))
  req_body_form_append(req, params)
}

#' @inheritParams jwt_claim
#' @export
#' @rdname oauth_client_req_auth
oauth_client_req_auth_jwt_sig <- function(req, client, claim, size = 256, header = list()) {
  claim <- exec("jwt_claim", !!!claim)
  jwt <- jwt_encode_sig(claim, key = client$key, size = size, header = header)

  # https://datatracker.ietf.org/doc/html/rfc7523#section-2.2
  params <- list(
    client_assertion = jwt,
    client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
  )
  req_body_form_append(req, params)
}

# Helpers -----------------------------------------------------------------

oauth_flow_check <- function(flow, client,
                             is_confidential = FALSE,
                             interactive = TRUE) {

  if (!inherits(client, "httr2_oauth_client")) {
    abort("`client` must be an OAuth client created with `oauth_client()`")
  }

  if (is_confidential && is.null(client$secret) && is.null(client$secret)) {
    abort(c(
      glue("Can't use this `app` with OAuth 2.0 {flow} flow"),
      "`app` must have a confidential client (i.e. `client_secret` is required)"
    ))
  }

  if (interactive && !is_interactive()) {
    abort(glue("OAuth 2.0 {flow} flow requires an interactive session"))
  }
}

oauth_client_get_token <- function(client, grant_type, ...) {
  req <- request(client$token_url)
  req <- req_body_form(req, list2(grant_type = grant_type, ...))
  req <- oauth_client_req_auth(req, client)
  req <- req_headers(req, Accept = "application/json")

  resp <- oauth_flow_fetch(req)
  exec(oauth_token, !!!resp)
}

