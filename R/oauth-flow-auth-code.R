#' OAuth authentication with authorization code
#'
#' @description
#' This uses [oauth_flow_auth_code()] to generate an access token, which is
#' then used to authentication the request with [req_auth_bearer_token()].
#' The token is automatically cached (either in memory or on disk) to minimise
#' the number of times the flow is performed.
#'
#' Learn more about the overall flow in `vignette("oauth")`.
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
#'   storing access credentials on disk. Cached tokens are encrypted,
#'   automatically deleted 30 days after creation, and stored in
#'   [oauth_cache_path()].
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
                                redirect_uri = "http://localhost",
                                host_name = deprecated(),
                                host_ip = deprecated(),
                                port = deprecated()
                                ) {

  redirect <- normalize_redirect_uri(
    redirect_uri = redirect_uri,
    host_name = host_name,
    host_ip = host_ip,
    port = port
  )

  params <- list(
    client = client,
    auth_url = auth_url,
    scope = scope,
    pkce = pkce,
    auth_params = auth_params,
    token_params = token_params,
    redirect_uri = redirect$uri
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
#' `oauth_flow_auth_code()` is a high-level wrapper that should work with APIs
#' that adhere relatively closely to the spec. When possible, it redirects the
#' browser back to a temporary local webserver to capture the authorization
#' code. When this is not possible (e.g. when running on a hosted platform
#' like RStudio Server) set `type = "web"` to instead prompts the user to enter
#' the code manually instead.
#'
#' The remaining low-level functions can be used to assemble a custom flow for
#' APIs that are further from the spec:
#'
#' * `oauth_flow_auth_code_url()` generates the url that should be opened in a
#'   browser.
#' * `oauth_flow_auth_code_listen()` starts a temporary local webserver that
#'   listens for the response from the resource server.
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
#' @param host_name,host_ip,port `r lifecycle::badge("deprecated")`
#'   Now use `redirect_uri` instead.
#' @param redirect_uri URL to redirect back to after authorization is complete.
#'   Often this must be registered with the API in advance.
#'
#'   httr2 supports two forms of redirect. Firstly, you can use a `localhost`
#'   url (the default), where httr2 will set up a temporary webserver to listen
#'   for the OAuth redirect. In this case, httr2 will automatically append a
#'   random port. If you need to set it to a fixed port because the API requires
#'   it, then specify it with (e.g.) `"http://localhost:1011"`. This technique
#'   works well when you are working on your own computer.
#'
#'   Alternatively, you can provide a URL to a website that uses javascript to
#'   give the user a code to copy and paste back into the R session (see
#'   <https://www.tidyverse.org/google-callback/> and
#'   <https://github.com/r-lib/gargle/blob/main/inst/pseudo-oob/google-callback/index.html>
#'   for examples). This is less convenient (because it requires more
#'   user interaction) but also works in hosted environments.
#'
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
                                 redirect_uri = "http://localhost",
                                 host_name = deprecated(),
                                 host_ip = deprecated(),
                                 port = deprecated()
) {

  oauth_flow_check("authorization code", client, interactive = TRUE)

  redirect <- normalize_redirect_uri(
    redirect_uri = redirect_uri,
    host_name = host_name,
    host_ip = host_ip,
    port = port
  )

  if (pkce) {
    code <- oauth_flow_auth_code_pkce()
    auth_params$code_challenge <- code$challenge
    auth_params$code_challenge_method <- code$method
    token_params$code_verifier <- code$verifier
  }

  state <- base64_url_rand(32)

  # Redirect user to authorisation url.
  user_url <- oauth_flow_auth_code_url(client,
    auth_url = auth_url,
    redirect_uri = redirect$uri,
    scope = scope,
    state = state,
    auth_params = auth_params
  )
  utils::browseURL(user_url)

  if (redirect$localhost) {
    # Listen on localhost for the result
    result <- oauth_flow_auth_code_listen(redirect$uri)
    code <- oauth_flow_auth_code_parse(result, state)
  } else {
    # Allow the user to retrieve the token out of band manually and enter it
    # into the console. This is what {gargle} terms the "pseudo out-of-band"
    # flow.
    code <- oauth_flow_auth_code_read(state)
  }

  # Get access/refresh token from authorisation code
  # https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3
  oauth_client_get_token(client,
    grant_type = "authorization_code",
    code = code,
    redirect_uri = redirect_uri,
    !!!token_params
  )
}

normalize_redirect_uri <- function(redirect_uri,
                                   host_name = deprecated(),
                                   host_ip = deprecated(),
                                   port = deprecated(),
                                   error_call = caller_env()) {

  parsed <- url_parse(redirect_uri)

  if (lifecycle::is_present(host_name)) {
    lifecycle::deprecate_warn(
      when = "0.3.0",
      what = "oauth_flow_auth_code(host_name)",
      with = "oauth_flow_auth_code(redirect_uri)"
    )
    parsed$hostname <- host_name
  }

  if (lifecycle::is_present(port)) {
    lifecycle::deprecate_warn(
      when = "0.3.0",
      what = "oauth_flow_auth_code(port)",
      with = "oauth_flow_auth_code(redirect_uri)"
    )
    parsed$port <- port
  }

  if (lifecycle::is_present(host_ip)) {
    lifecycle::deprecate_warn("0.3.0", "oauth_flow_auth_code(host_ip)")
  }

  localhost <- parsed$hostname == "localhost"

  if (localhost) {
    check_installed("httpuv", "desktop OAuth")
    if (is_hosted_session()) {
      cli::cli_abort(
        "Can't use localhost {.arg redirect_uri} in a hosted environment.",
        call = error_call
      )
    }

    if (is.null(parsed$port)) {
      parsed$port <- httpuv::randomPort()
    }
  }

  list(
    uri = url_build(parsed),
    localhost = localhost
  )

}

# Authorisation request: make a url that the user navigates to
# https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.1
#' @export
#' @rdname oauth_flow_auth_code
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
oauth_flow_auth_code_listen <- function(redirect_uri = "http://localhost:1410") {
  parsed <- url_parse(redirect_uri)
  port <- as.integer(parsed$port)
  path <- parsed$path %||% "/"

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
  server <- httpuv::startServer("127.0.0.1", port, list(call = listen))
  withr::defer(httpuv::stopServer(server))

  # TODO: make this a progress bar
  inform("Waiting for authentication in browser...")
  inform("Press Esc/Ctrl + C to abort")
  while (!complete) {
    httpuv::service()
  }
  httpuv::service() # send data back to client

  if (is.null(info)) {
    cli::cli_abort("Authentication failed; invalid url from server.")
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
    cli::cli_abort("Authentication failure: state does not match.")
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

# Try to determine whether we can redirect the user's browser to a server on
# localhost, which isn't possible if we are running on a hosted platform.
#
# Currently this detects RStudio Server, Posit Workbench, and Google Colab. It
# is based on the strategy pioneered by the {gargle} package.
is_hosted_session <- function() {
  if (nzchar(Sys.getenv("COLAB_RELEASE_TAG"))) {
    return(TRUE)
  }
  # If RStudio Server or Posit Workbench is running locally (which is possible,
  # though unusual), it's not acting as a hosted environment.
  Sys.getenv("RSTUDIO_PROGRAM_MODE") == "server" &&
    !grepl("localhost", Sys.getenv("RSTUDIO_HTTP_REFERER"), fixed = TRUE)
}

oauth_flow_auth_code_read <- function(state) {
  code <- trimws(readline("Enter authorization code or URL: "))
  # We support several options here:
  # 1) Parsing the code and state from the resolved URL on the redirect page
  #
  # 2) The original {gargle} style, where the user copy & pastes a
  #    base64-encoded JSON object with both the code and state. This is used on
  #    https://www.tidyverse.org/google-callback/; and
  #
  # 3) The full manual approach, where the code and state are entered
  #    independently.

  parsed <- url_parse(code)

  if (!is.null(parsed$query)) {
    result <- parsed$query
  } else {
    result <- tryCatch(
      jsonlite::fromJSON(rawToChar(openssl::base64_decode(code))),
      error = function(e) {
        list(
          code = code,
          state = trimws(readline("Enter state parameter: "))
        )
      })
  }

  if (!identical(result$state, state)) {
    abort("Authentication failure: state does not match")
  }

  result$code
}

# Make base::readline() mockable
readline <- NULL
