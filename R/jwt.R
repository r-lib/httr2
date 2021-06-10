#' Create and sign a JWT
#'
#' `jwt_claim_set()` creates a JWT claim set as defined by
#' [rfc7519](https://datatracker.ietf.org/doc/html/rfc7519).
#' `jwt_sign_rs256()` signs a claim set with the RS256 algorithm (used by both
#' Google and Azure), producing a JWT. These functions are used by
#' [req_oauth_jwt()] and [oauth_client_req_auth_jwt_rs256()].
#'
#' @param iss Issuer claim. Identifies the principal that issued the JWT.
#' @param sub Subject claim. Identifies the principal that is the subject of
#'   the JWT (i.e. the entity that the claims apply to).
#' @param aud Audience claim. Identifies the recipients that the JWT is
#'    intended. Each principle intended to process the JWT must be identifid
#'    with a unique value.
#' @param exp Expiration claim. Identifies the expiration time on or after which
#'   the JWT MUST NOT be accepted for processing. Defaults to 5 minutes.
#' @param nbf Not before claim. Identifies the time before which the JWT
#'   MUST NOT be accepted for processing. Defaults to current time.
#' @param iat Issued at claim. Identifies the time at which the JWT was
#'   issued.  Defaults to current time.
#' @param jti JWT ID claim. Provides a unique identifier for the JWT.
#'   If omitted, uses a random 32-byte sequence encoded with base64url.
#' @param ... Any additional claims to include in the claim set.
#' @export
jwt_claim_set <- function(iss = NULL,
                          sub = NULL,
                          aud = NULL,
                          exp = unix_time() + 5L * 60L,
                          nbf = unix_time(),
                          iat = unix_time(),
                          jti = NULL,
                          ...) {
  compact(list2(
    iss = iss,
    sub = sub,
    aud = aud,
    exp = exp,
    iat = iat,
    nbf = nbf,
    jti = jti %||% base64_url_rand(32),
    ...
  ))
}

#' @export
#' @rdname jwt_claim_set
#' @param claim_set Claim set produced by `jwt_claim_set()`
#' @param private_key Private key either specficied as a path to a file,
#'   a connection, or a string (PEM/SSH format), or a raw vector (DER format).
#' @param extra_headers Any additional fields to include in the JWT header.
jwt_sign_rs256 <- function(claim_set, private_key, extra_headers) {
  check_installed("jsonlite")
  key <- openssl::read_key(private_key)

  header <- list2(
    typ = "JWT",
    alg = "RS256",
    # https://datatracker.ietf.org/doc/html/rfc7515#section-4.1.7
    x5t = base64_url_encode(openssl::sha1(key)),
    !!!extra_headers
  )

  header_json <- jwt_base64(header)
  claim_set_json <- jwt_base64(claim_set_json)

  body <- paste0(header_json, ".", claim_set_json)
  sig <- openssl::signature_create(charToRaw(body), openssl::sha256, key)

  paste0(body, ".", base64_url_encode(sig))
}

jwt_base64 <- function(x) {
  base64_url_encode(jsonlite::toJSON(x, auto_unbox = TRUE))
}
