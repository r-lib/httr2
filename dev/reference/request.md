# Create a new HTTP request

There are three steps needed to perform a HTTP request with httr2:

1.  Create a request object with `request(url)` (this function).

2.  Define its behaviour with `req_` functions, e.g.:

    - [`req_headers()`](https://httr2.r-lib.org/dev/reference/req_headers.md)
      to set header values.

    - [`req_url_path()`](https://httr2.r-lib.org/dev/reference/req_url.md)
      and friends to modify the url.

    - [`req_body_json()`](https://httr2.r-lib.org/dev/reference/req_body.md)
      and friends to add a body.

    - [`req_auth_basic()`](https://httr2.r-lib.org/dev/reference/req_auth_basic.md)
      to perform basic HTTP authentication.

    - [`req_oauth_auth_code()`](https://httr2.r-lib.org/dev/reference/req_oauth_auth_code.md)
      to use the OAuth auth code flow.

3.  Perform the request and fetch the response with
    [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md).

## Usage

``` r
request(base_url)
```

## Arguments

- base_url:

  Base URL for request.

## Value

An HTTP request: an S3 list with class `httr2_request`.

## Examples

``` r
request("http://r-project.org")
#> <httr2_request>
#> GET http://r-project.org
#> Body: empty
```
