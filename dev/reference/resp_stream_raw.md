# Read a streaming body a chunk at a time

- `resp_stream_raw()` retrieves bytes (`raw` vectors).

- `resp_stream_lines()` retrieves lines of text (`character` vectors).

- `resp_stream_sse()` retrieves a single [server-sent
  event](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events).

- `resp_stream_aws()` retrieves a single event from an AWS stream (i.e.
  mime type \`application/vnd.amazon.eventstream“).

Use `resp_stream_is_complete()` to determine if there is further data
waiting on the stream.

## Usage

``` r
resp_stream_raw(resp, kb = 32)

resp_stream_lines(resp, lines = 1, max_size = Inf, warn = TRUE)

resp_stream_sse(resp, max_size = Inf)

resp_stream_aws(resp, max_size = Inf)

# S3 method for class 'httr2_response'
close(con, ...)

resp_stream_is_complete(resp)
```

## Arguments

- resp, con:

  A streaming
  [response](https://httr2.r-lib.org/dev/reference/response.md) created
  by
  [`req_perform_connection()`](https://httr2.r-lib.org/dev/reference/req_perform_connection.md).

- kb:

  How many kilobytes (1024 bytes) of data to read.

- lines:

  The maximum number of lines to return at once.

- max_size:

  The maximum number of bytes to buffer; once this number of bytes has
  been exceeded without a line/event boundary, an error is thrown.

- warn:

  Like [`readLines()`](https://rdrr.io/r/base/readLines.html): warn if
  the connection ends without a final EOL.

- ...:

  Not used; included for compatibility with generic.

## Value

- `resp_stream_raw()`: a raw vector.

- `resp_stream_lines()`: a character vector.

- `resp_stream_sse()`: a list with components `type`, `data`, and `id`.
  `type`, `data`, and `id` are always strings; `data` and `id` may be
  empty strings.

- `resp_stream_aws()`: a list with components `headers` and `body`.
  `body` will be automatically parsed if the event contents a
  `:content-type` header with `application/json`.

`resp_stream_sse()` and `resp_stream_aws()` will return `NULL` to signal
that the end of the stream has been reached or, if in nonblocking mode,
that no event is currently available.

## Examples

``` r
req <- request(example_url()) |>
  req_template("GET /stream/:n", n = 5)

con <- req |> req_perform_connection()
while (!resp_stream_is_complete(con)) {
  lines <- con |> resp_stream_lines(2)
  cat(length(lines), " lines received\n", sep = "")
}
#> 2 lines received
#> 2 lines received
#> 1 lines received
close(con)

# You can also see what's happening by setting verbosity
con <- req |> req_perform_connection(verbosity = 2)
#> -> GET /stream/5 HTTP/1.1
#> -> Host: 127.0.0.1:39853
#> -> User-Agent: httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/1.1 200 OK
#> <- Date: Thu, 04 Dec 2025 23:24:22 GMT
#> <- Content-Type: application/json
#> <- Transfer-Encoding: chunked
#> <- 
while (!resp_stream_is_complete(con)) {
  lines <- con |> resp_stream_lines(2)
}
#> << {"url":"http://127.0.0.1:39853/stream/5","args":{},"headers":{"Host":"127.0.0.1:39853","User-Agent":"httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0","Accept":"*/*","Accept-Encoding":"deflate, gzip, br, zstd"},"origin":"127.0.0.1","id":0}<< {"url":"http://127.0.0.1:39853/stream/5","args":{},"headers":{"Host":"127.0.0.1:39853","User-Agent":"httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0","Accept":"*/*","Accept-Encoding":"deflate, gzip, br, zstd"},"origin":"127.0.0.1","id":1}
#> << {"url":"http://127.0.0.1:39853/stream/5","args":{},"headers":{"Host":"127.0.0.1:39853","User-Agent":"httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0","Accept":"*/*","Accept-Encoding":"deflate, gzip, br, zstd"},"origin":"127.0.0.1","id":2}<< {"url":"http://127.0.0.1:39853/stream/5","args":{},"headers":{"Host":"127.0.0.1:39853","User-Agent":"httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0","Accept":"*/*","Accept-Encoding":"deflate, gzip, br, zstd"},"origin":"127.0.0.1","id":3}
#> << {"url":"http://127.0.0.1:39853/stream/5","args":{},"headers":{"Host":"127.0.0.1:39853","User-Agent":"httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0","Accept":"*/*","Accept-Encoding":"deflate, gzip, br, zstd"},"origin":"127.0.0.1","id":4}
close(con)
```
