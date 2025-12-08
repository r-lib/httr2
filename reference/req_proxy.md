# Use a proxy for a request

Use a proxy for a request

## Usage

``` r
req_proxy(
  req,
  url,
  port = NULL,
  username = NULL,
  password = NULL,
  auth = "basic"
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/reference/request.md)
  object.

- url, port:

  Location of proxy.

- username, password:

  Login details for proxy, if needed.

- auth:

  Type of HTTP authentication to use. Should be one of the following:
  `basic`, `digest`, `digest_ie`, `gssnegotiate`, `ntlm`, `any`.

## Examples

``` r
# Proxy from https://www.proxynova.com/proxy-server-list/
if (FALSE) { # \dontrun{
request("http://hadley.nz") |>
  req_proxy("20.116.130.70", 3128) |>
  req_perform()
} # }
```
