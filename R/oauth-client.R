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
#'   a little safer, I recommend using [obfuscate()] when recording the client
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
#'   (optionally) `client_secret` are added to the body. `"header"` sends the
#'   `client_id` and `client_secret` in HTTP Authorization header. `"jwt_sig"`
#'   will generate a JWT, and include it in a `client_assertion` field in the
#'   body.
#'
#'   See [oauth_client_req_auth()] for more details.
#' @param auth_params Additional parameters passed to the function specified
#'   by `auth`.
#' @param name Optional name for the client. Used when generating the cache
#'   directory. If `NULL`, generated from hash of `client_id`. If you're
#'   defining a client for use in a package, I recommend that you use
#'   the package name.
#' @return An OAuth client: An S3 list with class `httr2_oauth_client`.
#' @export
#' @examples
#' oauth_client("myclient", "http://example.com/token_url", secret = "DONTLOOK")
oauth_client <- function(
  id,
  token_url,
  secret = NULL,
  key = NULL,
  auth = c("body", "header", "jwt_sig"),
  auth_params = list(),
  name = hash(id)
) {
  check_string(id)
  check_string(token_url)
  check_string(secret, allow_null = TRUE)

  if (is.character(auth)) {
    if (missing(auth)) {
      auth <- if (is.null(key)) "body" else "jwt_sig"
    }
    auth <- arg_match(auth)

    if (auth == "header" && is.null(secret)) {
      cli::cli_abort("{.code auth = 'header'} requires a {.arg secret}.")
    } else if (auth == "jwt_sig") {
      if (is.null(key)) {
        cli::cli_abort("{.code auth = 'jwt_sig'} requires a {.arg key}.")
      }
      if (!has_name(auth_params, "claim")) {
        cli::cli_abort(
          "{.code auth = 'jwt_sig'} requires a claim specification in {.arg auth_params}."
        )
      }

      if (is_list(auth_params$claim)) {
        auth_params$claim <- exec("jwt_claim", !!!auth_params$claim)
      } else if (is.function(auth_params$claim)) {
        auth_params$claim <- auth_params$claim()
      } else {
        cli::cli_abort(
          "{.value claim} in {.arg auth_params} 
          must be a list or function."
        )
      }
    }

    auth <- paste0("oauth_client_req_auth_", auth)
  } else if (!is_function(auth)) {
    cli::cli_abort("{.arg auth} must be a string or function.")
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
  cli::cat_line(cli::style_bold("<", paste(class(x), collapse = "/"), ">"))
  redacted <- list_redact(compact(x), c("secret", "key"))
  bullets(redacted)
  invisible(x)
}

#' OAuth client authentication
#'
#' @description
#' `oauth_client_req_auth()` authenticates a request using the authentication
#' strategy defined by the `auth` and `auth_param` arguments to [oauth_client()].
#' This is used to authenticate the client as part of the OAuth flow, **not**
#' to authenticate a request on behalf of a user.
#'
#' There are three built-in strategies:
#'
#' * `oauth_client_req_body()` adds the client id and (optionally) the secret
#'   to the request body, as described in `r rfc(6749, "2.3.1")`.
#'
#' * `oauth_client_req_header()` adds the client id and secret using HTTP
#'   basic authentication with the `Authorization` header, as described
#'   in `r rfc(6749, "2.3.1")`.
#'
#' * `oauth_client_jwt_rs256()` adds a client assertion to the body using a
#'   JWT signed with `jwt_sign_rs256()` using a private key, as described
#'   in `r rfc(7523, 2.2)`.
#'
#' You will generally not call these functions directly but will instead
#' specify them through the `auth` argument to [oauth_client()]. The `req` and
#' `client` parameters are automatically filled in; other parameters come from
#' the `auth_params` argument.
#' @inheritParams req_perform
#' @param client An [oauth_client].
#' @return A modified HTTP [request].
#' @export
#' @examples
#' # Show what the various forms of client authentication look like
#' req <- request("https://example.com/whoami")
#'
#' client1 <- oauth_client(
#'   id = "12345",
#'   secret = "56789",
#'   token_url = "https://example.com/oauth/access_token",
#'   name = "oauth-example",
#'   auth = "body" # the default
#' )
#' # calls oauth_client_req_auth_body()
#' req_dry_run(oauth_client_req_auth(req, client1))
#'
#' client2 <- oauth_client(
#'   id = "12345",
#'   secret = "56789",
#'   token_url = "https://example.com/oauth/access_token",
#'   name = "oauth-example",
#'   auth = "header"
#' )
#' # calls oauth_client_req_auth_header()
#' req_dry_run(oauth_client_req_auth(req, client2))
#'
#' client3 <- oauth_client(
#'   id = "12345",
#'   key = openssl::rsa_keygen(),
#'   token_url = "https://example.com/oauth/access_token",
#'   name = "oauth-example",
#'   auth = "jwt_sig",
#'   auth_params = list(claim = jwt_claim())
#' )
#' # calls oauth_client_req_auth_header_jwt_sig()
#' req_dry_run(oauth_client_req_auth(req, client3))
oauth_client_req_auth <- function(req, client) {
  exec(client$auth, req = req, client = client, !!!client$auth_params)
}

#' @export
#' @rdname oauth_client_req_auth
oauth_client_req_auth_header <- function(req, client) {
  req_auth_basic(
    req,
    username = client$id,
    password = unobfuscate(client$secret)
  )
}

#' @export
#' @rdname oauth_client_req_auth
oauth_client_req_auth_body <- function(req, client) {
  req_body_form(
    req,
    client_id = client$id,
    client_secret = unobfuscate(client$secret) # might be NULL
  )
}

#' @inheritParams jwt_claim
#' @export
#' @rdname oauth_client_req_auth
oauth_client_req_auth_jwt_sig <- function(
  req,
  client,
  claim,
  size = 256,
  header = list()
) {
  claim <- exec("jwt_claim", !!!claim)
  jwt <- jwt_encode_sig(claim, key = client$key, size = size, header = header)

  # https://datatracker.ietf.org/doc/html/rfc7523#section-2.2
  req_body_form(
    req,
    client_assertion = jwt,
    client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
  )
}

# Helpers -----------------------------------------------------------------

oauth_flow_check <- function(
  flow,
  client,
  is_confidential = FALSE,
  interactive = FALSE,
  error_call = caller_env()
) {
  if (!inherits(client, "httr2_oauth_client")) {
    cli::cli_abort(
      "{.arg client} must be an OAuth client created with {.fn oauth_client}.",
      call = error_call
    )
  }

  if (is_confidential && is.null(client$secret) && is.null(client$key)) {
    cli::cli_abort(
      c(
        "Can't use this {.arg app} with OAuth 2.0 {flow} flow.",
        i = "{.arg app} must have a confidential client (i.e. {.arg client_secret} is required)."
      ),
      call = error_call
    )
  }

  if (interactive && !is_interactive()) {
    cli::cli_abort(
      "OAuth 2.0 {flow} flow requires an interactive session",
      call = error_call
    )
  }
}

oauth_client_get_token <- function(
  client,
  grant_type,
  ...,
  error_call = caller_env()
) {
  req <- request(client$token_url)
  req <- req_body_form(req, grant_type = grant_type, ...)
  req <- oauth_client_req_auth(req, client)
  req <- req_headers(req, Accept = "application/json")

  resp <- oauth_flow_fetch(req, "client$token_url", error_call = error_call)
  exec(oauth_token, !!!resp)
}
