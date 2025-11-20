# Set time limit for a request

An error will be thrown if the request does not complete in the time
limit.

## Usage

``` r
req_timeout(req, seconds)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- seconds:

  Maximum number of seconds to wait

## Value

A modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md).

## Examples

``` r
# Give up after at most 10 seconds
request("http://example.com") |> req_timeout(10)
#> <httr2_request>
#> GET http://example.com
#> Body: empty
#> Options:
#> * timeout_ms    : 10000
#> * connecttimeout: 0
```
