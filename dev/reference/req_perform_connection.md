# Perform a request and return a streaming connection

Use `req_perform_connection()` to perform a request if you want to
stream the response body. A response returned by
`req_perform_connection()` includes a connection as the body. You can
then use
[`resp_stream_raw()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md),
[`resp_stream_lines()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md),
or
[`resp_stream_sse()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md)
to retrieve data a chunk at a time. Always finish up by closing the
connection by calling `close(response)`.

This is an alternative interface to
[`req_perform_stream()`](https://httr2.r-lib.org/dev/reference/req_perform_stream.md)
that returns a [connection](https://rdrr.io/r/base/connections.html)
that you can use to pull the data, rather than providing callbacks that
the data is pushed to. This is useful if you want to do other work in
between handling inputs from the stream.

## Usage

``` r
req_perform_connection(
  req,
  blocking = TRUE,
  verbosity = NULL,
  mock = getOption("httr2_mock", NULL)
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- blocking:

  When retrieving data, should the connection block and wait for the
  desired information or immediately return what it has (possibly
  nothing)?

- verbosity:

  How much information to print? This is a wrapper around
  [`req_verbose()`](https://httr2.r-lib.org/dev/reference/req_verbose.md)
  that uses an integer to control verbosity:

  - `0`: no output

  - `1`: show headers

  - `2`: show headers and bodies as they're streamed

  - `3`: show headers, bodies, curl status messages, raw SSEs, and
    stream buffer management

  Use
  [`with_verbosity()`](https://httr2.r-lib.org/dev/reference/with_verbosity.md)
  to control the verbosity of requests that you can't affect directly.

- mock:

  A mocking function. If supplied, this function is called with the
  request. It should return either `NULL` (if it doesn't want to handle
  the request) or a
  [response](https://httr2.r-lib.org/dev/reference/response.md) (if it
  does). See
  [`with_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)/[`local_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)
  for more details.

## Examples

``` r
req <- request(example_url()) |>
  req_url_path("/stream-bytes/32768")
resp <- req_perform_connection(req)

length(resp_stream_raw(resp, kb = 16))
#> [1] 16384
length(resp_stream_raw(resp, kb = 16))
#> [1] 16384
# When the stream has no more data, you'll get an empty result:
length(resp_stream_raw(resp, kb = 16))
#> [1] 0

# Always close the response when you're done
close(resp)

# You can loop until complete with resp_stream_is_complete()
resp <- req_perform_connection(req)
while (!resp_stream_is_complete(resp)) {
  print(length(resp_stream_raw(resp, kb = 12)))
}
#> [1] 12288
#> [1] 12288
#> [1] 8192
close(resp)
```
