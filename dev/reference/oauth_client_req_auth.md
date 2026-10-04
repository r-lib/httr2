# OAuth client authentication

`oauth_client_req_auth()` authenticates a request using the
authentication strategy defined by the `auth` and `auth_param` arguments
to
[`oauth_client()`](https://httr2.r-lib.org/dev/reference/oauth_client.md).
This is used to authenticate the client as part of the OAuth flow,
**not** to authenticate a request on behalf of a user.

There are three built-in strategies:

- `oauth_client_req_body()` adds the client id and (optionally) the
  secret to the request body, as described in [Section 2.3.1 of RFC
  6749](https://datatracker.ietf.org/doc/html/rfc6749#section-2.3.1).

- `oauth_client_req_header()` adds the client id and secret using HTTP
  basic authentication with the `Authorization` header, as described in
  [Section 2.3.1 of RFC
  6749](https://datatracker.ietf.org/doc/html/rfc6749#section-2.3.1).

- `oauth_client_jwt_rs256()` adds a client assertion to the body using a
  JWT signed with `jwt_sign_rs256()` using a private key, as described
  in [Section 2.2 of RFC
  7523](https://datatracker.ietf.org/doc/html/rfc7523#section-2.2).

You will generally not call these functions directly but will instead
specify them through the `auth` argument to
[`oauth_client()`](https://httr2.r-lib.org/dev/reference/oauth_client.md).
The `req` and `client` parameters are automatically filled in; other
parameters come from the `auth_params` argument.

## Usage

``` r
oauth_client_req_auth(req, client)

oauth_client_req_auth_header(req, client)

oauth_client_req_auth_body(req, client)

oauth_client_req_auth_jwt_sig(
  req,
  client,
  claim = NULL,
  size = 256,
  header = list()
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- client:

  An
  [oauth_client](https://httr2.r-lib.org/dev/reference/oauth_client.md).

- claim:

  Claim set produced by
  [`jwt_claim()`](https://httr2.r-lib.org/dev/reference/jwt_claim.md).

- size:

  Size, in bits, of sha2 signature, i.e. 256, 384 or 512. Only for
  HMAC/RSA, not applicable for ECDSA keys.

- header:

  A named list giving additional fields to include in the JWT header.

## Value

A modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md).

## Examples

``` r
# Show what the various forms of client authentication look like
req <- request("https://example.com/whoami")

client1 <- oauth_client(
  id = "12345",
  secret = "56789",
  token_url = "https://example.com/oauth/access_token",
  name = "oauth-example",
  auth = "body" # the default
)
# calls oauth_client_req_auth_body()
req_dry_run(oauth_client_req_auth(req, client1))
#> POST /whoami HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> content-length: 35
#> content-type: application/x-www-form-urlencoded
#> host: example.com
#> user-agent: httr2/1.3.0.9000 r-curl/8.0.0 libcurl/8.5.0
#> 
#> client_id=12345&client_secret=56789

client2 <- oauth_client(
  id = "12345",
  secret = "56789",
  token_url = "https://example.com/oauth/access_token",
  name = "oauth-example",
  auth = "header"
)
# calls oauth_client_req_auth_header()
req_dry_run(oauth_client_req_auth(req, client2))
#> GET /whoami HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> authorization: <REDACTED>
#> host: example.com
#> user-agent: httr2/1.3.0.9000 r-curl/8.0.0 libcurl/8.5.0
#> 

client3 <- oauth_client(
  id = "12345",
  key = openssl::rsa_keygen(),
  token_url = "https://example.com/oauth/access_token",
  name = "oauth-example",
  auth = "jwt_sig",
  auth_params = list(claim = jwt_claim())
)
# calls oauth_client_req_auth_header_jwt_sig()
req_dry_run(oauth_client_req_auth(req, client3))
#> POST /whoami HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> content-length: 623
#> content-type: application/x-www-form-urlencoded
#> host: example.com
#> user-agent: httr2/1.3.0.9000 r-curl/8.0.0 libcurl/8.5.0
#> 
#> client_assertion=eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJleHAiOjE3OTExNDk4OTgsIm5iZiI6MTc5MTE0OTU5OCwiaWF0IjoxNzkxMTQ5NTk4LCJqdGkiOiJROUF5U2VNQzJXNjlwdHJYNGl1YWRTSk5nMVRnNXI2R1hGYms1Zy03cF9vIn0.WSUtK7T_WPCEuexjOeqm34ycsCfQMqV97SlmHCfgRCwcTeeIYiF-5w_fudMJ9S_44a25E5cwuptaFxxKx0dmamSTi3nuKG0k0vrMe1vQX2E9z9y_PlYYsW5BpCy-QvJtCAgWvKihF9M-1_iWW2bvExwg_DyqIR5HRrmSWFIZfNFD1upQcZH_o8DP4LfGFBtD3hjn3iztRKTugc1slXvNOskg1vv1VLfc7_6BDVIX-ymnKZQbmqbyn6BMTwniKQb0kwTKam5KwxpHK7GHQt3y--cgyjAQVlSuCVPL4LoFDc8qljtXA6get6ZTR9xZ6wjSljI2htHsj7hbW5ooWcyIhw&client_assertion_type=urn%3Aietf%3Aparams%3Aoauth%3Aclient-assertion-type%3Ajwt-bearer
```
