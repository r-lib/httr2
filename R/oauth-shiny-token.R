#' Set OAuth Token in Shiny App Cookie
#'
#' This function sets a JSON Web Token (JWT) and stores it in a cookie so the
#' user can be successfully identified and skip login when returning to the app.
#' The token is stored in a httponly, secure cookie and signed with HMAC. Claims
#' include `identifier`, `name`, `email`, `aud` and `sub`.
#'
#' @param claims A list containing the claims to be included in the JWT.
#' @param cookie A string representing the name of the cookie where the JWT will
#'   be stored.
#' @param key A secret key used to sign the JWT.
#' @param token_validity Integer specifying the expiration time of the JWT in
#'   seconds.
#'
#' @return None. The function sets the cookie in the HTTP response header.
oauth_shiny_set_app_token <- function(claims, cookie, key, token_validity) {
  claims_subset <- subset(claims, !names(claims) %in% c("exp"))
  jwt <- rlang::exec(jwt_claim, !!!claims_subset, exp = unix_time() + token_validity)
  jwt_enc <- jwt_encode_hmac(jwt, charToRaw(key))

  oauth_shiny_set_cookie_header(
    name = cookie,
    value = jwt_enc,
    cookie_opts = cookie_options(max_age = token_validity)
  )
}

#' Get OAuth Token from Shiny App Cookie
#'
#' This function retrieves and decodes the JWT stored in a specified cookie from
#' the incoming request.
#'
#' @param cookie A string representing the name of the cookie where the JWT is
#'   stored. Default is `oauth_app_token`.
#' @param key The secret key used in the application.
#' @param session Defaults to `shiny::getDefaultReactiveDomain()`
#'
#' @return A decoded JWT if the cookie exists and is valid; otherwise, `NULL`.
#' @export
oauth_shiny_get_app_token <- function(cookie = "oauth_app_token",
                                      key = oauth_shiny_app_passphrase(),
                                      session = shiny::getDefaultReactiveDomain()) {
  oauth_shiny_get_app_token_from_request(session$request, cookie, key)
}

#' Get OAuth Token from Shiny App Cookie
#'
#' This function retrieves and decodes the JWT stored in a specified cookie from
#' the incoming request.
#'
#' @param req The incoming request object from which the cookie is to be
#'   extracted.
#' @param cookie A string representing the name of the cookie where the JWT is
#'   stored. Default is `oauth_app_token`.
#' @param key The secret key used in the application.
#'
#' @return A decoded JWT if the cookie exists and is valid; otherwise, `NULL`.
oauth_shiny_get_app_token_from_request <- function(req, cookie = "oauth_app_token", key) {
  cookies <- parse_cookies(req)
  cookie <- cookies[[cookie]]

  # If no cookie exists, return NULL
  if (is.null(cookie) || cookie == "") {
    return(NULL)
  }

  # If token decoding fails, return NULL
  decoded_token <- tryCatch(
    {
      jose::jwt_decode_hmac(cookie, charToRaw(key))
    },
    error = function(e) {
      cli::cli_alert_warning("Failed to decode app token from cookie")
      cli::cli_li(e$message)
      return(NULL)
    }
  )

  # If identifier in claims is not included, return NULL
  if (is.null(decoded_token$identifier) || decoded_token$identifier == "") {
    return(NULL)
  }

  decoded_token
}

#' Set OAuth Client Access Token in Shiny App Cookie
#'
#' This function stores an OAuth access token in a cookie, encrypting it before
#' storage. The token is an `oauth_token` object containing access_token and
#' related information.
#'
#' @param client An `oauth_shiny_client` representing the client configuration
#' @param token A list representing the OAuth token to be stored.
#' @param key A secret key used for encrypting the token.
#'
#' @return None. The function sets the encrypted token in the HTTP response
#'   header as a cookie.
oauth_shiny_set_access_token <- function(client, token, key) {
  if (is.null(client$access_token_validity) || client$access_token_validity > 0) {
    expires_at <- as.integer(token[["expires_at"]] - as.numeric(Sys.time()))
    max_age <- min(expires_at, client$access_token_validity)

    # Since shiny can't read expiry time of a cookie, add it to the token
    token[["cookie_expires_at"]] <- unix_time() + max_age

    oauth_shiny_set_cookie_header(
      name = client$client_cookie_name,
      value = oauth_shiny_encrypt_client_token(client, token, key, max_age),
      cookie_opts = cookie_options(max_age = max_age)
    )
  }
}

#' Get OAuth Client Access Token from Shiny App Cookie
#'
#' This function retrieves and decrypts an OAuth token stored in a cookie.
#' It automatically handles chunked cookies if the encrypted token exceeds
#' maximum cookie size (e.g. `oauth_app_google_token_1` and
#' `oauth_app_google_token2`)
#'
#' @param client A list representing the client configuration,
#' including the client name and secret.
#' @param key A secret key used to decrypt the token.
#' @param session The current Shiny session object, used to access request
#' details. Default is `shiny::getDefaultReactiveDomain()`.
#'
#' @return A decrypted `oauth_token` if the cookie exists and is valid
#' @export
oauth_shiny_get_access_token <- function(client,
                                         key = oauth_shiny_app_passphrase(),
                                         session = shiny::getDefaultReactiveDomain()) {
  cookie_name <- paste0("oauth_app_", client$name, "_token")
  cookies <- parse_cookies(session$request)
  # If client contains chunked cookies, paste them together
  cookie <- paste(cookies[grepl(cookie_name, names(cookies))], collapse = "")

  if (cookie == "") {
    return(NULL)
  }

  key <- paste0(key, client$secret)

  token <- tryCatch(
    oauth_shiny_decrypt_client_token(cookie, key),
    error = function(e) {
      cli::cli_alert_warning("Failed attempt to retrieve client cookie {.field {cookie_name}}")
      cli::cli_ul()
      cli::cli_li(e$message)
      return(NULL)
    }
  )
  token
}

#' Decrypt OAuth Access Token
#'
#' This function decrypts an OAuth access token stored in a cookie.
#'
#' @param cookie A string representing the encrypted cookie value.
#' @param key A secret key used to decrypt the cookie.
#'
#' @return A decrypted OAuth token object.
oauth_shiny_decrypt_client_token <- function(cookie, key) {
  bytes <- sodium::hex2bin(cookie)

  if (length(bytes) <= 32 + 24) {
    stop("Cookie payload was too short")
  }

  salt <- bytes[1:32]
  nonce <- bytes[32 + (1:24)]
  rest <- utils::tail(bytes, -(32 + 24))

  key_scrypt <- sodium::scrypt(charToRaw(key), salt = salt, size = 32)

  # Decrypt cookie
  cleartext <- sodium::data_decrypt(rest, key = key_scrypt, nonce = nonce)

  cleartext <- rawToChar(cleartext)
  Encoding(cleartext) <- "UTF-8"

  # Decode and verify signature and validity
  decoded_token <- jose::jwt_decode_hmac(cleartext, charToRaw(key))

  token <- jsonlite::fromJSON(decoded_token[["token"]])

  reserved_args <- c("token_type", "access_token", "refresh_token", "expires_at")
  meta <- subset(token, !names(token) %in% reserved_args)

  expires_at <- token[["expires_at"]]

  if (!is.null(expires_at)) {
    expires_in <- floor(expires_at - as.numeric(Sys.time()))
  } else {
    expires_in <- NULL
  }

  oauth_token(
    token_type = token$token_type,
    access_token = token$access_token,
    expires_in = expires_in,
    refresh_token = token$refresh_token,
    !!!meta
  )
}

#' Encrypt OAuth Client Access Token
#'
#' This function encrypts an OAuth access token for storage in a cookie.
#'
#' @param client A list representing the client configuration, including the
#'   client secret.
#' @param token A list representing the OAuth token to be encrypted.
#' @param key A secret key used to encrypt the token.
#' @param max_age Integer specifying the expiration time of the token in
#'   seconds.
#'
#' @return A string representing the encrypted token in hexadecimal format.
oauth_shiny_encrypt_client_token <- function(client, token, key, max_age) {
  jwt <- jwt_claim(
    exp = unix_time() + max_age,
    token = jsonlite::toJSON(unclass(token), auto_unbox = TRUE)
  )

  key <- paste0(key, client$secret)
  cred <- jwt_encode_hmac(jwt, charToRaw(key))

  salt <- sodium::random(32)
  nonce <- sodium::random(24)
  key_scrypt <- sodium::scrypt(charToRaw(key), salt = salt, size = 32)
  ciphertext <- sodium::data_encrypt(charToRaw(cred), key = key_scrypt, nonce = nonce)

  sodium::bin2hex(c(salt, nonce, ciphertext))
}
