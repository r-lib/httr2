#' Create and encode a JWT
#'
#' `jwt_claim()` is a wrapper around [jose::jwt_claim()] that creates a JWT
#' claim set with a few extra default values. `jwt_encode_sig()` and
#' `jwt_encode_hmac()` are thin wrappers around [jose::jwt_encode_sig()] and
#' [jose::jwt_encode_hmac()] that exist primarily to make specification
#' in other functions a little simpler.
#'
#' @param iss Issuer claim. Identifies the principal that issued the JWT.
#' @param sub Subject claim. Identifies the principal that is the subject of
#'   the JWT (i.e. the entity that the claims apply to).
#' @param aud Audience claim. Identifies the recipients that the JWT is
#'    intended. Each principle intended to process the JWT must be identified
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
#' @returns An S3 list with class `jwt_claim`.
#' @keywords internal
#' @export
#' @examples
#' claim <- jwt_claim()
#' str(claim)
jwt_claim <- function(iss = NULL,
                      sub = NULL,
                      aud = NULL,
                      exp = unix_time() + 5L * 60L,
                      nbf = unix_time(),
                      iat = unix_time(),
                      jti = NULL,
                      ...) {
  # https://datatracker.ietf.org/doc/html/rfc7519
  jose::jwt_claim(
    iss = iss,
    sub = sub,
    aud = aud,
    exp = exp,
    iat = iat,
    nbf = nbf,
    jti = jti %||% base64_url_rand(32),
    ...
  )
}

#' @export
#' @rdname jwt_claim
#' @param claim Claim set produced by [jwt_claim()].
#' @param key RSA or EC private key either specified as a path to a file,
#'   a connection, or a string (PEM/SSH format), or a raw vector (DER format).
#' @param size Size, in bits, of sha2 signature, i.e. 256, 384 or 512.
#'   Only for HMAC/RSA, not applicable for ECDSA keys.
#' @param header A named list giving additional fields to include in the
#'   JWT header.
jwt_encode_sig <- function(claim, key, size = 256, header = list()) {
  check_installed("jose")
  jose::jwt_encode_sig(claim, key, size = size, header = header)
}

#' @export
#' @rdname jwt_claim
#' @param secret String or raw vector with a secret passphrase.
jwt_encode_hmac <- function(claim, secret, size = size, header = list()) {
  check_installed("jose")
  jose::jwt_encode_sig(claim, secret, size = size, header = header)
}
