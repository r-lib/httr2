# Perform a request and handle data as it streams back

**\[deprecated\]**

Please use
[`req_perform_connection()`](https://httr2.r-lib.org/reference/req_perform_connection.md)
instead.

After preparing a request, call `req_perform_stream()` to perform the
request and handle the result with a streaming callback. This is useful
for streaming HTTP APIs where potentially the stream never ends.

The `callback` will only be called if the result is successful. If you
need to stream an error response, you can use
[`req_error()`](https://httr2.r-lib.org/reference/req_error.md) to
suppress error handling so that the body is streamed to you.

## Usage

``` r
req_perform_stream(
  req,
  callback,
  timeout_sec = Inf,
  buffer_kb = 64,
  round = c("byte", "line")
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/reference/request.md)
  object.

- callback:

  A single argument callback function. It will be called repeatedly with
  a raw vector whenever there is at least `buffer_kb` worth of data to
  process. It must return `TRUE` to continue streaming.

- timeout_sec:

  Number of seconds to process stream for.

- buffer_kb:

  Buffer size, in kilobytes.

- round:

  How should the raw vector sent to `callback` be rounded? Choose
  `"byte"`, `"line"`, or supply your own function that takes a raw
  vector of `bytes` and returns the locations of possible cut points (or
  [`integer()`](https://rdrr.io/r/base/integer.html) if there are none).

## Value

An HTTP [response](https://httr2.r-lib.org/reference/response.md). The
body will be empty if the request was successful (since the `callback`
function will have handled it). The body will contain the HTTP response
body if the request was unsuccessful.

## Examples

``` r
# PREVIOSULY
show_bytes <- function(x) {
  cat("Got ", length(x), " bytes\n", sep = "")
  TRUE
}
resp <- request(example_url()) |>
  req_url_path("/stream-bytes/100000") |>
  req_perform_stream(show_bytes, buffer_kb = 32)
#> Warning: `req_perform_stream()` was deprecated in httr2 1.2.0.
#> ℹ Please use `req_perform_connection()` instead.
#> Got 32768 bytes
#> Got 32768 bytes
#> Got 32768 bytes
#> Got 1696 bytes

# NOW
resp <- request(example_url()) |>
  req_url_path("/stream-bytes/100000") |>
  req_perform_connection()
while (!resp_stream_is_complete(resp)) {
  x <-  resp_stream_raw(resp, kb = 32)
  cat("Got ", length(x), " bytes\n", sep = "")
}
#> Got 32768 bytes
#> Got 32768 bytes
#> Got 32768 bytes
#> Got 1696 bytes
close(resp)
```
