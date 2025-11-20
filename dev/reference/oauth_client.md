# Create an OAuth client

An OAuth app is the combination of a client, a set of endpoints (i.e.
urls where various requests should be sent), and an authentication
mechanism. A client consists of at least a `client_id`, and also often a
`client_secret`. You'll get these values when you create the client on
the API's website.

## Usage

``` r
oauth_client(
  id,
  token_url,
  secret = NULL,
  key = NULL,
  auth = c("body", "header", "jwt_sig"),
  auth_params = list(),
  name = hash(id)
)
```

## Arguments

- id:

  Client identifier.

- token_url:

  Url to retrieve an access token.

- secret:

  Client secret. For most apps, this is technically confidential so in
  principle you should avoid storing it in source code. However, many
  APIs require it in order to provide a user friendly authentication
  experience, and the risks of including it are usually low. To make
  things a little safer, I recommend using
  [`obfuscate()`](https://httr2.r-lib.org/dev/reference/obfuscate.md)
  when recording the client secret in public code.

- key:

  Client key. As an alternative to using a `secret`, you can instead
  supply a confidential private key. This should never be included in a
  package.

- auth:

  Authentication mechanism used by the client to prove itself to the
  API. Can be one of three built-in methods ("body", "header", or
  "jwt"), or a function that will be called with arguments `req`,
  `client`, and the contents of `auth_params`.

  The most common mechanism in the wild is `"body"` where the
  `client_id` and (optionally) `client_secret` are added to the body.
  `"header"` sends the `client_id` and `client_secret` in HTTP
  Authorization header. `"jwt_sig"` will generate a JWT, and include it
  in a `client_assertion` field in the body.

  See
  [`oauth_client_req_auth()`](https://httr2.r-lib.org/dev/reference/oauth_client_req_auth.md)
  for more details.

- auth_params:

  Additional parameters passed to the function specified by `auth`.

- name:

  Optional name for the client. Used when generating the cache
  directory. If `NULL`, generated from hash of `client_id`. If you're
  defining a client for use in a package, I recommend that you use the
  package name.

## Value

An OAuth client: An S3 list with class `httr2_oauth_client`.

## Examples

``` r
oauth_client("myclient", "http://example.com/token_url", secret = "DONTLOOK")
#> <httr2_oauth_client>
#> * name     : "920903ca1274bc747bb367c6b5abe4a4"
#> * id       : "myclient"
#> * secret   : <REDACTED>
#> * token_url: "http://example.com/token_url"
#> * auth     : "oauth_client_req_auth_body"
```
