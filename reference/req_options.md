# Set arbitrary curl options in request

`req_options()` is for expert use only; it allows you to directly set
libcurl options to access features that are otherwise not available in
httr2.

## Usage

``` r
req_options(.req, ...)
```

## Arguments

- .req:

  A [request](https://httr2.r-lib.org/reference/request.md).

- ...:

  \<[`dynamic-dots`](https://rlang.r-lib.org/reference/dyn-dots.html)\>
  Name-value pairs. The name should be a valid curl option, as found in
  [`curl::curl_options()`](https://jeroen.r-universe.dev/curl/reference/curl_options.html).

## Value

A modified HTTP [request](https://httr2.r-lib.org/reference/request.md).

## Examples

``` r
# req_options() allows you to access curl options that are not otherwise
# exposed by httr2. For example, in very special cases you may need to
# turn off SSL verification. This is generally a bad idea so httr2 doesn't
# provide a convenient wrapper, but if you really know what you're doing
# you can still access this libcurl option:
req <- request("https://example.com") |>
  req_options(ssl_verifypeer = 0)
```
