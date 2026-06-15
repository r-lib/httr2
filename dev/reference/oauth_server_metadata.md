# Discover OAuth server metadata

`oauth_server_metadata()` fetches and parses an OAuth 2.0 Authorization
Server Metadata document ([RFC
8414](https://datatracker.ietf.org/doc/html/rfc8414)) or OpenID Connect
Discovery document, returning the endpoints advertised by an issuer. Use
it to discover values like `authorization_endpoint`, `token_endpoint`,
and `device_authorization_endpoint` rather than hard-coding them:

    meta <- oauth_server_metadata("https://accounts.google.com")
    client <- oauth_client("id", token_url = meta$token_endpoint, secret = "...")
    oauth_flow_auth_code(client, auth_url = meta$authorization_endpoint)

As a security measure, the `issuer` reported in the returned document is
validated against the requested `issuer` ([Section 3.3 of RFC
8414](https://datatracker.ietf.org/doc/html/rfc8414#section-3.3)); a
mismatch is an error. This check is skipped when `url` is supplied
without `issuer`.

## Usage

``` r
oauth_server_metadata(issuer, type = c("openid", "oauth"), url = NULL)
```

## Arguments

- issuer:

  The issuer URL, e.g. `"https://accounts.google.com"`. The metadata URL
  is derived from it according to `type`.

- type:

  Which well-known suffix to use when `url` is not supplied:

  - `"openid"` (the default) appends
    `/.well-known/openid-configuration`, the form served by essentially
    every major provider. Despite the name, it is a superset that also
    advertises the OAuth endpoints, so it is the better default even for
    plain OAuth.

  - `"oauth"` inserts `/.well-known/oauth-authorization-server` between
    the origin and any path, as defined in [RFC
    8414](https://datatracker.ietf.org/doc/html/rfc8414). Use this for
    the few providers that serve only the OAuth document.

- url:

  Optionally, the full metadata document URL. Use this as an escape
  hatch for providers that follow neither well-known convention. When
  supplied, `issuer` is only used for validation and can be omitted.

## Value

An S3 list with class `httr2_oauth_server_metadata` containing the full
parsed metadata document. Endpoints that the provider does not advertise
are simply absent.

## See also

Other OAuth flows:
[`req_oauth_auth_code()`](https://httr2.r-lib.org/dev/reference/req_oauth_auth_code.md),
[`req_oauth_bearer_jwt()`](https://httr2.r-lib.org/dev/reference/req_oauth_bearer_jwt.md),
[`req_oauth_client_credentials()`](https://httr2.r-lib.org/dev/reference/req_oauth_client_credentials.md),
[`req_oauth_password()`](https://httr2.r-lib.org/dev/reference/req_oauth_password.md),
[`req_oauth_refresh()`](https://httr2.r-lib.org/dev/reference/req_oauth_refresh.md),
[`req_oauth_token_exchange()`](https://httr2.r-lib.org/dev/reference/req_oauth_token_exchange.md)

## Examples

``` r
oauth_server_metadata("https://accounts.google.com")
#> <httr2_oauth_server_metadata>
#> * issuer                       : "https://accounts.google.com"
#> * authorization_endpoint       : "https://accounts.google.com/o/oauth2/v2/auth"
#> * device_authorization_endpoint: "https://oauth2.googleapis.com/device/code"
#> * token_endpoint               : "https://oauth2.googleapis.com/token"
#> * userinfo_endpoint            : "https://openidconnect.googleapis.com/v1/userinfo"
#> * revocation_endpoint          : "https://oauth2.googleapis.com/revoke"
#> * jwks_uri                     : "https://www.googleapis.com/oauth2/v3/certs"
#> * and 10 more fields.
```
