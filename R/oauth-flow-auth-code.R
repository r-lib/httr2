#' OAuth authentication with authorization code
#'
#' @description
#' This uses [oauth_flow_auth_code()] to generate an access token, which is
#' then used to authentication the request with [req_auth_bearer_token()].
#' The token is automatically cached (either in memory or on disk) to minimise
#' the number of times the flow is performed.
#'
#' # Security considerations
#'
#' The authorization code flow is used for both web applications and native
#' applications (which are equivalent to R packages).
#' [rfc8252](https://datatracker.ietf.org/doc/html/rfc8252) spells out
#' important considerations for native apps. Most importantly there's no way
#' for native apps to keep secrets from their users. This means that the
#' server should either not require a `client_secret` (i.e. a public client
#' not an confidential client) or ensure that possession of the `client_secret`
#' doesn't bestow any meaningful rights.
#'
#' Only modern APIs from the bigger players (Azure, Google, etc) explicitly
#' native apps. However, in most cases, even for older APIs, possessing the
#' `client_secret` gives you no ability to do anything harmful, so our
#' general principle is that it's fine to include it in an R package, as long
#' as it's mildly obfuscated to protect it from credential scraping. There's
#' no incentive to steal your client credentials if it takes less time to
#' create a new client than find your client secret.
#'
#' @export
#' @inheritParams req_perform
#' @param cache_disk Should the access token be cached on disk? This reduces
#'   the number of times that you need to re-authenticate at the cost of
#'   storing access credentials on disk. Cached tokens are encrypted and
#'   automatically deleted 30 days after creation.
#' @param cache_key If you want to cache multiple tokens per app, use this
#'   key to disambiguate them.
#' @returns A modified HTTP [request].
#' @inheritParams oauth_flow_auth_code
#' @examples
#' client <- oauth_client(
#'   id = "28acfec0674bb3da9f38",
#'   secret = obfuscated(paste0(
#'      "J9iiGmyelHltyxqrHXW41ZZPZamyUNxSX1_uKnv",
#'      "PeinhhxET_7FfUs2X0LLKotXY2bpgOMoHRCo"
#'   )),
#'   token_url = "https://github.com/login/oauth/access_token",
#'   name = "hadley-oauth-test"
#' )
#'
#' request("https://api.github.com/user") %>%
#'   req_oauth_auth_code(client, auth_url = "https://github.com/login/oauth/authorize")
req_oauth_auth_code <- function(req, client,
                                auth_url,
                                cache_disk = FALSE,
                                cache_key = NULL,
                                scope = NULL,
                                pkce = TRUE,
                                auth_params = list(),
                                token_params = list(),
                                host_name = "localhost",
                                host_ip = "127.0.0.1",
                                port = httpuv::randomPort()
                                ) {

  params <- list(
    client = client,
    auth_url = auth_url,
    scope = scope,
    pkce = pkce,
    auth_params = auth_params,
    token_params = token_params,
    host_name = host_name,
    host_ip = host_ip,
    port = port
  )

  cache <- cache_choose(client, cache_disk, cache_key)
  req_oauth(req, "oauth_flow_auth_code", params, cache = cache)
}

#' OAuth flow: authorization code
#'
#' @description
#' These functions implement the OAuth authorization code flow, as defined
#' by [rfc6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1),
#' Section 4.1. This is the most commonly used OAuth flow where the user is
#' opens a page in their browser, approves the access, and then returns to R.
#'
#' `oauth_flow_auth_code()` is a high-level wrapper that should
#' work with APIs that adhere relatively closely to the spec. The remaining
#' low-level functions can be used to assemble a custom flow for APIs that are
#' further from the spec:
#'
#' * `oauth_flow_auth_code_url()` generates the url where the user is sent.
#' * `oauth_flow_auth_code_listen()` starts an webserver that listens for
#'   the response from the resource server.
#' * `oauth_flow_auth_code_parse()` parses the query parameters returned from
#'   the server redirect, verifying that the `state` is correct, and returning
#'   the authorisation code.
#' * `oauth_flow_auth_code_pkce()` generates code verifier, method, and challenge
#'   components as needed for PKCE, as defined in
#'   [rfc7636](https://datatracker.ietf.org/doc/html/rfc7636).
#'
#' @family OAuth flows
#' @param client An [oauth_client()].
#' @param auth_url Authorization url; you'll need to discover this by reading
#'   the documentation.
#' @param scope Scopes to be requested from the resource owner.
#' @param pkce Use "Proof Key for Code Exchange"? This adds an extra layer of
#'   security and should always be used if supported by the server.
#' @param auth_params List containing additional parameters passed to `oauth_flow_auth_code_url()`
#' @param token_params List containing additional parameters passed to the
#'   `token_url`.
#' @param host_name Host name used to generate `redirect_uri`
#' @param host_ip IP address web server will be bound to.
#' @param port Port to bind web server to. By default, this uses a random port.
#'   You may need to set it to a fixed port if the API requires that the
#'   `redirect_uri` specified in the client exactly matches the `redirect_uri`
#'   generated by this function.
#' @returns An [oauth_token].
#' @export
#' @keywords internal
#' @examples
#' client <- oauth_client(
#'   id = "28acfec0674bb3da9f38",
#'   secret = obfuscated(paste0(
#'      "J9iiGmyelHltyxqrHXW41ZZPZamyUNxSX1_uKnv",
#'      "PeinhhxET_7FfUs2X0LLKotXY2bpgOMoHRCo"
#'   )),
#'   token_url = "https://github.com/login/oauth/access_token",
#'   name = "hadley-oauth-test"
#' )
#' if (interactive()) {
#'   token <- oauth_flow_auth_code(client, auth_url = "https://github.com/login/oauth/authorize")
#'   token
#' }
oauth_flow_auth_code <- function(client,
                                 auth_url,
                                 scope = NULL,
                                 pkce = TRUE,
                                 auth_params = list(),
                                 token_params = list(),
                                 host_name = "localhost",
                                 host_ip = "127.0.0.1",
                                 port = httpuv::randomPort()
) {
  oauth_flow_check("authorization code", client, interactive = TRUE)
  check_installed("httpuv")

  if (pkce) {
    code <- oauth_flow_auth_code_pkce()
    auth_params$code_challenge <- code$challenge
    auth_params$code_challenge_method <- code$method
    token_params$code_verifier <- code$verifier
  }

  state <- base64_url_rand(32)
  redirect_url <- paste0("http://", host_name, ":", port, "/")

  # Redirect user to authorisation url, and listen for result
  user_url <- oauth_flow_auth_code_url(client,
    auth_url = auth_url,
    redirect_uri = redirect_url,
    scope = scope,
    state = state,
    auth_params = auth_params
  )
  utils::browseURL(user_url)
  result <- oauth_flow_auth_code_listen(
    host_ip = host_ip,
    port = port,
    path = url_parse(redirect_url)$path
  )
  code <- oauth_flow_auth_code_parse(result, state)

  # Get access/refresh token from authorisation code
  # https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3
  oauth_client_get_token(client,
    grant_type = "authorization_code",
    code = code,
    redirect_uri = redirect_url,
    !!!token_params
  )
}

# Authorisation request: make a url that the user navigates to
# https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.1
#' @export
#' @rdname oauth_flow_auth_code
#' @param redirect_uri URL to which user should be redirected.
#' @param state Random state generated by `oauth_flow_auth_code()`. Used to
#'   verify that we're working with an authentication request that we created.
#'   (This is an unlikely threat for R packages since the webserver that
#'   listens for authorization responses is transient.)
oauth_flow_auth_code_url <- function(client,
                                     auth_url,
                                     redirect_uri = NULL,
                                     scope = NULL,
                                     state = NULL,
                                     auth_params = list()) {
  url <- url_parse(auth_url)
  url$query <- modify_list(url$query,
    response_type = "code",
    client_id = client$id,
    redirect_uri = redirect_uri,
    scope = scope,
    state = state,
    !!!auth_params
  )
  url_build(url)
}

#' @export
#' @rdname oauth_flow_auth_code
#' @param path Path to listen on; defaults to `/`.
oauth_flow_auth_code_listen <- function(host_ip = "127.0.0.1",
                                        port = 1410,
                                        path = NULL) {

  check_string(path, allow_null = TRUE, allow_empty = FALSE)
  path <- path %||% "/"

  complete <- FALSE
  info <- NULL
  listen <- function(env) {
    if (!identical(env$PATH_INFO, path)) {
      return(list(
        status = 404L,
        headers = list("Content-Type" = "text/plain"),
        body = "Not found"
      ))
    }

    query <- env$QUERY_STRING
    if (!is.character(query) || identical(query, "")) {
      complete <<- TRUE
    } else {
      complete <<- TRUE
      info <<- parse_form_urlencoded(query)
    }

    list(
      status = 200L,
      headers = list("Content-Type" = "text/plain"),
      body = "Authentication complete. Please close this page and return to R."
    )
  }
  server <- httpuv::startServer(host_ip, port, list(call = listen))
  withr::defer(httpuv::stopServer(server))

  # TODO: make this a progress bar
  inform("Waiting for authentication in browser...")
  inform("Press Esc/Ctrl + C to abort")
  while (!complete) {
    httpuv::service()
  }
  httpuv::service() # send data back to client

  if (is.null(info)) {
    abort("Authentication failed; invalid url from server.")
  }

  info
}

# application/x-www-form-urlencoded defined in
# https://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.1
# Spaces are first replaced by +
parse_form_urlencoded <- function(query) {
  query <- query_parse(query)
  query[] <- gsub("+", " ", query, fixed = TRUE)
  query
}

# Authorisation response: get query params back from redirect
# https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2
#' @export
#' @rdname oauth_flow_auth_code
#' @param query List of query parameters returned by `oauth_flow_auth_code_listen()`.
oauth_flow_auth_code_parse <- function(query, state) {
  if (has_name(query, "error")) {
    # https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2.1
    # Never see problems with redirect_uri
    oauth_flow_abort(query$error, query$error_description, query$error_uri)
  }

  if (query$state != state) {
    abort("Authentication failure: state does not match")
  }

  query$code
}

#' @export
#' @rdname oauth_flow_auth_code
oauth_flow_auth_code_pkce <- function() {
  # https://datatracker.ietf.org/doc/html/rfc7636#section-4.1
  #
  # It is RECOMMENDED that the output of a suitable random number generator
  # be used to create a 32-octet sequence.  The octet sequence is then
  # base64url-encoded to produce a 43-octet URL safe string to use as the
  # code verifier.
  verifier <- base64_url_rand(32)

  list(
    verifier = verifier,
    method = "S256",
    challenge = base64_url_encode(openssl::sha256(charToRaw(verifier)))
  )
}
