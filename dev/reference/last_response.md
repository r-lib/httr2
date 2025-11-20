# Retrieve most recent request/response

`last_request()` and `last_response()` retrieve the most recent request
made by httr2 and the response it received, to facilitate debugging
problems *after* they occur.

`last_request_json()` and `last_response_json()` return the JSON bodies
of the most recent request and response. They will error if not JSON.

## Usage

``` r
last_response()

last_request()

last_request_json(pretty = TRUE)

last_response_json(pretty = TRUE)
```

## Arguments

- pretty:

  Should the JSON be pretty-printed?

## Value

`last_request()` and `last_response()` return an HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md) or
[response](https://httr2.r-lib.org/dev/reference/response.md)
respectively. If no request has been made, `last_request()` will return
`NULL`; if no request has been made or the last request was
unsuccessful, `last_response()` will return `NULL`.

`last_request_json()` and `last_response_json()` always return a string.
They will error if `last_request()` or `last_response()` are `NULL` or
don't have JSON bodies.

## Examples

``` r
. <- request("http://httr2.r-lib.org") |> req_perform()
last_request()
#> <httr2_request>
#> GET http://httr2.r-lib.org
#> Body: empty
last_response()
#> <httr2_response>
#> GET https://httr2.r-lib.org/
#> Status: 200 OK
#> Content-Type: text/html
#> Body: In memory (19168 bytes)

. <- request(example_url("/post")) |>
  req_body_json(list(a = 1, b = 2)) |>
  req_perform()
last_request_json()
#> {
#>   "a": 1,
#>   "b": 2
#> }
last_request_json(pretty = FALSE)
#> {"a":1,"b":2}
last_response_json()
#> {
#>   "args": {
#> 
#>   },
#>   "data": "{\"a\":1,\"b\":2}",
#>   "files": {
#> 
#>   },
#>   "form": {
#> 
#>   },
#>   "headers": {
#>     "Host": "127.0.0.1:36963",
#>     "User-Agent": "httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0",
#>     "Accept": "*/*",
#>     "Accept-Encoding": "deflate, gzip, br, zstd",
#>     "Content-Type": "application/json",
#>     "Content-Length": "13"
#>   },
#>   "json": {
#>     "a": 1,
#>     "b": 2
#>   },
#>   "method": "post",
#>   "path": "/post",
#>   "origin": "127.0.0.1",
#>   "url": "http://127.0.0.1:36963/post"
#> }
last_response_json(pretty = FALSE)
#> {
#>   "args": {},
#>   "data": "{\"a\":1,\"b\":2}",
#>   "files": {},
#>   "form": {},
#>   "headers": {
#>     "Host": "127.0.0.1:36963",
#>     "User-Agent": "httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0",
#>     "Accept": "*/*",
#>     "Accept-Encoding": "deflate, gzip, br, zstd",
#>     "Content-Type": "application/json",
#>     "Content-Length": "13"
#>   },
#>   "json": {
#>     "a": 1,
#>     "b": 2
#>   },
#>   "method": "post",
#>   "path": "/post",
#>   "origin": "127.0.0.1",
#>   "url": "http://127.0.0.1:36963/post"
#> }
```
