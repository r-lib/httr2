# Send data in request body

- `req_body_file()` sends a local file.

- `req_body_raw()` sends a string or raw vector.

- `req_body_json()` sends JSON encoded data. Named components of this
  data can later be modified with `req_body_json_modify()`.

- `req_body_form()` sends form encoded data.

- `req_body_multipart()` creates a multi-part body.

Adding a body to a request will automatically switch the method to POST.

## Usage

``` r
req_body_raw(req, body, type = "")

req_body_file(req, path, type = "")

req_body_json(
  req,
  data,
  auto_unbox = TRUE,
  digits = 22,
  null = "null",
  type = "application/json",
  ...
)

req_body_json_modify(req, ...)

req_body_form(.req, ..., .multi = c("error", "comma", "pipe", "explode"))

req_body_multipart(.req, ...)
```

## Arguments

- req, .req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- body:

  A literal string or raw vector to send as body.

- type:

  MIME content type. The default, `""`, will not emit a `Content-Type`
  header. Ignored if you have set a `Content-Type` header with
  [`req_headers()`](https://httr2.r-lib.org/dev/reference/req_headers.md).

- path:

  Path to file to upload.

- data:

  Data to include in body.

- auto_unbox:

  Should length-1 vectors be automatically "unboxed" to JSON scalars?

- digits:

  How many digits of precision should numbers use in JSON?

- null:

  Should `NULL` be translated to JSON's null (`"null"`) or an empty list
  (`"list"`).

- ...:

  \<[`dynamic-dots`](https://rlang.r-lib.org/reference/dyn-dots.html)\>
  Name-data pairs used to send data in the body.

  - For `req_body_form()`, the values must be strings (or things easily
    coerced to strings). Vectors are converted to strings using the
    value of `.multi`.

  - For `req_body_multipart()` the values must be strings or objects
    produced by
    [`curl::form_file()`](https://jeroen.r-universe.dev/curl/reference/multipart.html)/[`curl::form_data()`](https://jeroen.r-universe.dev/curl/reference/multipart.html).

  - For `req_body_json_modify()`, any simple data made from atomic
    vectors and lists.

  `req_body_json()` uses this argument differently; it takes additional
  arguments passed on to
  [`jsonlite::toJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html).

- .multi:

  Controls what happens when a value is a vector:

  - `"error"`, the default, throws an error.

  - `"comma"`, separates values with a `,`, e.g. `?x=1,2`.

  - `"pipe"`, separates values with a `|`, e.g. `?x=1|2`.

  - `"explode"`, turns each element into its own parameter, e.g.
    `?x=1&x=2`

  If none of these options work for your needs, you can instead supply a
  function that takes a character vector of argument values and returns
  a a single string.

## Value

A modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md).

## Examples

``` r
req <- request(example_url()) |>
  req_url_path("/post")

# Most APIs expect small amounts of data in either form or json encoded:
req |>
  req_body_form(x = "A simple text string") |>
  req_dry_run()
#> POST /post HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> content-length: 28
#> content-type: application/x-www-form-urlencoded
#> host: 127.0.0.1:41463
#> user-agent: httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0
#> 
#> x=A%20simple%20text%20string

req |>
  req_body_json(list(x = "A simple text string")) |>
  req_dry_run()
#> POST /post HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> content-length: 28
#> content-type: application/json
#> host: 127.0.0.1:41463
#> user-agent: httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0
#> 
#> {
#>   "x": "A simple text string"
#> }

# For total control over the body, send a string or raw vector
req |>
  req_body_raw("A simple text string") |>
  req_dry_run()
#> POST /post HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> content-length: 20
#> host: 127.0.0.1:41463
#> user-agent: httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0
#> 
#> <20 bytes>

# There are two main ways that APIs expect entire files
path <- tempfile()
writeLines(letters[1:6], path)

# You can send a single file as the body:
req |>
  req_body_file(path) |>
  req_dry_run()
#> POST /post HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> content-length: 12
#> host: 127.0.0.1:41463
#> user-agent: httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0
#> 
#> <12 bytes>

# You can send multiple files, or a mix of files and data
# with multipart encoding
req |>
  req_body_multipart(a = curl::form_file(path), b = "some data") |>
  req_dry_run()
#> POST /post HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> content-length: 334
#> content-type: multipart/form-data; boundary=------------------------a6keInUNztdhh83M3v9vtR
#> host: 127.0.0.1:41463
#> user-agent: httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0
#> 
#> --------------------------a6keInUNztdhh83M3v9vtR
#> Content-Disposition: form-data; name="a"; filename="file19a36e13fdd6"
#> Content-Type: application/octet-stream
#> 
#> a
#> b
#> c
#> d
#> e
#> f
#> 
#> --------------------------a6keInUNztdhh83M3v9vtR
#> Content-Disposition: form-data; name="b"
#> 
#> some data
#> --------------------------a6keInUNztdhh83M3v9vtR--
#> 
```
