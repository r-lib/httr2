# Create and encode a JWT

`jwt_claim()` is a wrapper around
[`jose::jwt_claim()`](https://r-lib.r-universe.dev/jose/reference/jwt_claim.html)
that creates a JWT claim set with a few extra default values.
`jwt_encode_sig()` and `jwt_encode_hmac()` are thin wrappers around
[`jose::jwt_encode_sig()`](https://r-lib.r-universe.dev/jose/reference/jwt_encode.html)
and
[`jose::jwt_encode_hmac()`](https://r-lib.r-universe.dev/jose/reference/jwt_encode.html)
that exist primarily to make specification in other functions a little
simpler.

## Usage

``` r
jwt_claim(
  iss = NULL,
  sub = NULL,
  aud = NULL,
  exp = unix_time() + 5L * 60L,
  nbf = unix_time(),
  iat = unix_time(),
  jti = NULL,
  ...
)

jwt_encode_sig(claim, key, size = 256, header = list())

jwt_encode_hmac(claim, secret, size = 256, header = list())
```

## Arguments

- iss:

  Issuer claim. Identifies the principal that issued the JWT.

- sub:

  Subject claim. Identifies the principal that is the subject of the JWT
  (i.e. the entity that the claims apply to).

- aud:

  Audience claim. Identifies the recipients that the JWT is intended.
  Each principle intended to process the JWT must be identified with a
  unique value.

- exp:

  Expiration claim. Identifies the expiration time on or after which the
  JWT MUST NOT be accepted for processing. Defaults to 5 minutes.

- nbf:

  Not before claim. Identifies the time before which the JWT MUST NOT be
  accepted for processing. Defaults to current time.

- iat:

  Issued at claim. Identifies the time at which the JWT was issued.
  Defaults to current time.

- jti:

  JWT ID claim. Provides a unique identifier for the JWT. If omitted,
  uses a random 32-byte sequence encoded with base64url.

- ...:

  Any additional claims to include in the claim set.

- claim:

  Claim set produced by `jwt_claim()`.

- key:

  RSA or EC private key either specified as a path to a file, a
  connection, or a string (PEM/SSH format), or a raw vector (DER
  format).

- size:

  Size, in bits, of sha2 signature, i.e. 256, 384 or 512. Only for
  HMAC/RSA, not applicable for ECDSA keys.

- header:

  A named list giving additional fields to include in the JWT header.

- secret:

  String or raw vector with a secret passphrase.

## Value

An S3 list with class `jwt_claim`.

## Examples

``` r
claim <- jwt_claim()
str(claim)
#> List of 4
#>  $ exp: num 1.76e+09
#>  $ nbf: num 1.76e+09
#>  $ iat: num 1.76e+09
#>  $ jti: chr "7wnWdGQXHxB-1U5hDzMYkklsNMQBCzBIEdK9ZnjLYBY"
#>  - attr(*, "class")= chr [1:2] "jwt_claim" "list"
```
