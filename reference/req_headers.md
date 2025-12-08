# Modify request headers

`req_headers()` allows you to set the value of any header.

`req_headers_redacted()` is a variation that adds "redacted" headers,
which httr2 avoids printing on the console. This is good practice for
authentication headers to avoid accidentally leaking them in log files.

## Usage

``` r
req_headers(.req, ..., .redact = NULL)

req_headers_redacted(.req, ...)
```

## Arguments

- .req:

  A [request](https://httr2.r-lib.org/reference/request.md).

- ...:

  \<[`dynamic-dots`](https://rlang.r-lib.org/reference/dyn-dots.html)\>
  Name-value pairs of headers and their values.

  - Use `NULL` to reset a value to httr2's default.

  - Use `""` to remove a header.

  - Use a character vector to repeat a header.

- .redact:

  A character vector of headers to redact. The Authorization header is
  always redacted.

## Value

A modified HTTP [request](https://httr2.r-lib.org/reference/request.md).

## Examples

``` r
req <- request("http://example.com")

# Use req_headers() to add arbitrary additional headers to the request
req |>
  req_headers(MyHeader = "MyValue") |>
  req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> host: example.com
#> myheader: MyValue
#> user-agent: httr2/1.2.2 r-curl/7.0.0 libcurl/8.5.0
#> 

# Repeated use overrides the previous value:
req |>
  req_headers(MyHeader = "Old value") |>
  req_headers(MyHeader = "New value") |>
  req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> host: example.com
#> myheader: New value
#> user-agent: httr2/1.2.2 r-curl/7.0.0 libcurl/8.5.0
#> 

# Setting Accept to NULL uses curl's default:
req |>
  req_headers(Accept = NULL) |>
  req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> host: example.com
#> user-agent: httr2/1.2.2 r-curl/7.0.0 libcurl/8.5.0
#> 

# Setting it to "" removes it:
req |>
  req_headers(Accept = "") |>
  req_dry_run()
#> GET / HTTP/1.1
#> accept-encoding: deflate, gzip, br, zstd
#> host: example.com
#> user-agent: httr2/1.2.2 r-curl/7.0.0 libcurl/8.5.0
#> 

# If you need to repeat a header, provide a vector of values
# (this is rarely needed, but is important in a handful of cases)
req |>
  req_headers(HeaderName = c("Value 1", "Value 2", "Value 3")) |>
  req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> headername: Value 1,Value 2,Value 3
#> host: example.com
#> user-agent: httr2/1.2.2 r-curl/7.0.0 libcurl/8.5.0
#> 

# If you have headers in a list, use !!!
headers <- list(HeaderOne = "one", HeaderTwo = "two")
req |>
  req_headers(!!!headers, HeaderThree = "three") |>
  req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> headerone: one
#> headerthree: three
#> headertwo: two
#> host: example.com
#> user-agent: httr2/1.2.2 r-curl/7.0.0 libcurl/8.5.0
#> 

# Use `req_headers_redacted()`` to hide a header in the output
req_secret <- req |>
  req_headers_redacted(Secret = "this-is-private") |>
  req_headers(Public = "but-this-is-not")

req_secret
#> <httr2_request>
#> GET http://example.com
#> Headers:
#> * Secret: <REDACTED>
#> * Public: "but-this-is-not"
#> Body: empty
req_secret |> req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> host: example.com
#> public: but-this-is-not
#> secret: <REDACTED>
#> user-agent: httr2/1.2.2 r-curl/7.0.0 libcurl/8.5.0
#> 
```
