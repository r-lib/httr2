#' Create an OAuth app
#'
#' An OAuth app is the combination of a client, a set of endpoints
#' (i.e. urls where various requests should be sent), and an authentication
#' mechanism. A client consists of at least a `client_id`, and also often
#' a `client_secret`. You'll get these values when you create the client on
#' the API's website.
#'
#' @param client A OAuth client created with `oauth_client()`.
#' @param endpoints A named character vector of endpoints. The precise endpoints
#'   required depend on the flow that you'll use, but all require a `token`
#'   endpoint that returns an access token.
#' @param auth Authentication mechanism used by the client to prove itself to
#'   the API. Can be one of three built-in methods ("body", "header", or "jwt"),
#'   or a function that will be called with arguments `req`, `client`, and
#'   the contents of `auth_params`.
#'
#'   The most common mechanism in the wild is `"body"` where the `client_id` and
#'   (optionally) `client_secret` are added to the body. `"header"` sends in
#'   `client_id` and `client_secret` in HTTP Authorization header. `"jwt_s256"`
#'   generate a JWT claim set signed with RS256.
#'
#'   See [oauth_client_req_auth()] for more details.
#' @param auth_params Additional parameters passed to the function specified
#'   by `auth`.
#' @export
oauth_app <- function(client,
                      endpoints,
                      auth = c("body", "header", "jwt_rs256"),
                      auth_params = list()
                      ) {
  if (!inherits(client, "httr2_oauth_client")) {
    abort("`client` must be an OAuth client created with `oauth_client()`")
  }

  if (!is.character(endpoints) || !is_named(endpoints)) {
    abort("`endpoints` must be a named character vector")
  }
  if (!has_name(endpoints, "token")) {
    abort("`endpoints` must contain a token endpoint")
  }

  if (is.character(auth)) {
    auth <- arg_match(auth)
    if (auth == "header" && is.null(client$secret)) {
      abort("`auth = 'header' requires a client with a secret")
    }
    auth <- paste0("oauth_client_req_auth_", auth)
  } else if (!is_function(auth)) {
    abort("`auth` must be a string or function")
  }

  structure(
    list(
      client = client,
      endpoints = endpoints,
      auth = auth,
      auth_params = auth_params
    ),
    class = "httr2_oauth_app"
  )
}

oauth_client_name <- function(app) {
  app$client$name %||% hash(c(httr::parse_url(app$endpoints[[1]])$hostname, app$client$id))
}

#' @export
#' @rdname oauth_app
#' @param client_id Client identifier.
#' @param client_secret Client secret. This is technically confidential so you
#'   should avoid storing it in source code where possible. However, many APIs
#'   require it in order to provide a user friendly authentication experience,
#'   and the risks of including it are usually low. To make things a little
#'   safer, I recommend using [obfuscate()] to store an obfuscated version of
#'   the source.
#' @param name Optional name for the client. Used when generating cache
#'   directory. If `NULL`, generated from hash of app hostname and
#'   `client_id`.
oauth_client <- function(client_id, client_secret = NULL, name = NULL) {
  structure(
    list(
      id = client_id,
      secret = client_secret,
      name = name
    ),
    class = "httr2_oauth_client"
  )
}

#' @export
print.httr2_oauth_client <- function(x, ...) {
  type <- if (is.null(x$secret)) "public" else "confidental"
  cli::cli_text("{.cls {class(x)}} ID: {x$id} ({type})")
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
#' specify them through the `auth` argument to [oauth_app()]. The `req` and
#' `client` parameters are automatically filled in; other parameters come from
#' the `auth_params` argument.
#' @param req A [request].
#' @param app An [oauth_app].
#' @param client An [oauth_client].
oauth_client_req_auth <- function(req, app) {
  exec(app$auth, req = req, client = app$client, !!!app$auth_params)
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

#' @param claims A list of claims passed to [jwt_claim_set].
#' @param key Path to private key file used to sign the JWT.
#' @export
#' @rdname oauth_client_req_auth
oauth_client_req_auth_jwt_rs256 <- function(req, client, claims, key) {
  claim_set <- jwt_claim_set(!!!claims)
  jwt <- jwt_sign_rs256(claim_set, key)

  # https://datatracker.ietf.org/doc/html/rfc7523#section-2.2
  params <- list(
    client_assertion = jwt,
    client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
  )
  req_body_form_append(req, params)
}

# Helpers -----------------------------------------------------------------

check_app <- function(app) {
  if (!inherits(app, "httr2_oauth_app")) {
    abort("`app` must be an OAuth app created with `oauth_app()`")
  }
}

oauth_flow_check_app <- function(app, flow,
                                 is_confidential = FALSE,
                                 endpoints = character(),
                                 interactive = TRUE) {
  check_app(app)

  if (is_confidential && is.null(app$client$secret)) {
    abort(c(
      glue("Can't use this `app` with OAuth 2.0 {flow} flow"),
      "`app` must have a confidential client (i.e. `client_secret` is required)"
    ))
  }

  missing <- setdiff(endpoints, names(app$endpoints))
  if (length(missing)) {
    abort(c(
      glue("Can't use this `app` with OAuth 2.0 {flow} flow"),
      glue("`app` lacks endpoints '{missing}'")
    ))
  }

  if (interactive && !is_interactive()) {
    abort(glue("OAuth 2.0 {flow} flow requires an interactive session"))
  }
}

app_endpoint <- function(app, endpoint) {
  if (!has_name(app$endpoints, endpoint)) {
    abort("app missing endpoint '{endpoint}'")
  }
  app$endpoints[[endpoint]]
}
