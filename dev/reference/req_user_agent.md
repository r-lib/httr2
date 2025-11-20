# Set user-agent for a request

This overrides the default user-agent set by httr2 which includes the
version numbers of httr2, the curl package, and libcurl.

## Usage

``` r
req_user_agent(req, string = NULL)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- string:

  String to be sent in the `User-Agent` header. If `NULL`, will user
  default.

## Value

A modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md).

## Examples

``` r
# Default user-agent:
request("http://example.com") |> req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> host: example.com
#> user-agent: httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0
#> 

request("http://example.com") |> req_user_agent("MyString") |> req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> host: example.com
#> user-agent: MyString
#> 

# If you're wrapping in an API in a package, it's polite to set the
# user agent to identify your package.
request("http://example.com") |>
  req_user_agent("MyPackage (http://mypackage.com)") |>
  req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> host: example.com
#> user-agent: MyPackage (http://mypackage.com)
#> 
```
