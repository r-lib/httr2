# Perform a dry run

This shows you exactly what httr2 will send to the server, without
actually sending anything. It requires the httpuv package because it
works by sending the real HTTP request to a local webserver, thanks to
the magic of
[`curl::curl_echo()`](https://jeroen.r-universe.dev/curl/reference/curl_echo.html).

## Usage

``` r
req_dry_run(
  req,
  quiet = FALSE,
  redact_headers = TRUE,
  testing_headers = is_testing(),
  pretty_json = getOption("httr2_pretty_json", TRUE)
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/reference/request.md)
  object.

- quiet:

  If `TRUE` doesn't print anything.

- redact_headers:

  Redact confidential data in the headers? Currently redacts the
  contents of the Authorization header to prevent you from accidentally
  leaking credentials when debugging/reprexing.

- testing_headers:

  If `TRUE`, removes headers that httr2 would otherwise be automatically
  added, which are likely to change across test runs. This currently
  includes:

  - The default `User-Agent`, which varies based on libcurl, curl, and
    httr2 versions.

  - The \`Host“ header, which is often set to a testing server.

  - The `Content-Length` header, which will often vary by platform
    because of varying newline encodings. (And is also not correct if
    you have `pretty_json = TRUE`.)

  - The `Accept-Encoding` header, which varies based on how libcurl was
    built.

- pretty_json:

  If `TRUE`, automatically prettify JSON bodies.

## Value

Invisibly, a list containing information about the request, including
`method`, `path`, and `headers`.

## Details

### Limitations

- The HTTP version is always `HTTP/1.1` (since you can't determine what
  it will actually be without connecting to the real server).

## Examples

``` r
# httr2 adds default User-Agent, Accept, and Accept-Encoding headers
request("http://example.com") |> req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> host: example.com
#> user-agent: httr2/1.2.2 r-curl/7.0.0 libcurl/8.5.0
#> 

# the Authorization header is automatically redacted to avoid leaking
# credentials on the console
req <- request("http://example.com") |> req_auth_basic("user", "password")
req |> req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> authorization: <REDACTED>
#> host: example.com
#> user-agent: httr2/1.2.2 r-curl/7.0.0 libcurl/8.5.0
#> 

# if you need to see it, use redact_headers = FALSE
req |> req_dry_run(redact_headers = FALSE)
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> authorization: Basic dXNlcjpwYXNzd29yZA==
#> host: example.com
#> user-agent: httr2/1.2.2 r-curl/7.0.0 libcurl/8.5.0
#> 
```
