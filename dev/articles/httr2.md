# httr2

The goal of this document is show you the basics of httr2. You’ll learn
how to create and submit HTTP requests and work with the HTTP responses
that you get back. httr2 is designed to map closely to the underlying
HTTP protocol, which I’ll explain as we go along. For more details, I
also recommend “[An overview of
HTTP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview)” from
MDN.

``` r
library(httr2)
```

## Create a request

In httr2, you start by creating a request. If you’re familiar with httr,
this a big change: with httr you could only submit a request,
immediately receiving a response. Having an explicit request object
makes it easier to build up a complex request piece by piece and works
well with the pipe.

Every request starts with a URL:

``` r
req <- request(example_url())
req
#> <httr2_request>
#> GET http://127.0.0.1:45521/
#> Body: empty
```

Here, instead of an external website, we use a test server that’s
built-in to httr2 itself. That ensures that this vignette will work
regardless of when or where you run it.

We can see exactly what this request will send to the server with a dry
run:

``` r
req |> req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> host: 127.0.0.1:45521
#> user-agent: httr2/1.2.2.9000 r-curl/7.0.0 libcurl/8.5.0
```

The first line of the request contains three important pieces of
information:

- The HTTP **method**, which is a verb that tells the server what you
  want to do. Here it’s GET, the most common verb, indicating that we
  want to *get* a resource. Other verbs include POST, to create a new
  resource, PUT, to replace an existing resource, and DELETE, to delete
  a resource.

- The **path**, which is the URL stripped of details that the server
  already knows, i.e. the protocol (`http` or `https`), the host
  (`localhost`), and the port (`45521`).

- The version of the HTTP protocol. This is unimportant for our purposes
  because it’s handled at a lower level.

The following lines specify the HTTP **headers**, a series of name-value
pairs separated by `:`. The headers in this request were automatically
added by httr2, but you can override them or add your own with
[`req_headers()`](https://httr2.r-lib.org/dev/reference/req_headers.md):

``` r
req |>
  req_headers(
    Name = "Hadley",
    `Shoe-Size` = "11",
    Accept = "application/json"
  ) |>
  req_dry_run()
#> GET / HTTP/1.1
#> accept: application/json
#> accept-encoding: deflate, gzip, br, zstd
#> host: 127.0.0.1:45521
#> name: Hadley
#> shoe-size: 11
#> user-agent: httr2/1.2.2.9000 r-curl/7.0.0 libcurl/8.5.0
```

Header names are case-insensitive, and servers will ignore headers that
they don’t understand.

The headers finish with a blank line which is followed by the **body**.
The requests above (like all GET requests) don’t have a body, so let’s
add one to see what happens. The `req_body_*()` functions provide a
variety of ways to add data to the body. Here we’ll use
[`req_body_json()`](https://httr2.r-lib.org/dev/reference/req_body.md)
to add some data encoded as JSON:

``` r
req |>
  req_body_json(list(x = 1, y = "a")) |>
  req_dry_run()
#> POST / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> content-length: 15
#> content-type: application/json
#> host: 127.0.0.1:45521
#> user-agent: httr2/1.2.2.9000 r-curl/7.0.0 libcurl/8.5.0
#> 
#> {
#>   "x": 1,
#>   "y": "a"
#> }
```

What’s changed?

- The method has changed from GET to POST. POST is the standard method
  for sending data to a website, and is automatically used whenever you
  add a body. Use
  [`req_method()`](https://httr2.r-lib.org/dev/reference/req_method.md)
  to use a different method.

- There are two new headers: `Content-Type` and `Content-Length`. They
  tell the server how to interpret the body — it’s encoded as JSON and
  is 15 bytes long.

- We have a body, consisting of some JSON.

Different servers want data encoded differently so httr2 provides a
selection of common formats. For example,
[`req_body_form()`](https://httr2.r-lib.org/dev/reference/req_body.md)
uses the encoding used when you submit a form from a web browser:

``` r
req |>
  req_body_form(x = "1", y = "a") |>
  req_dry_run()
#> POST / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> content-length: 7
#> content-type: application/x-www-form-urlencoded
#> host: 127.0.0.1:45521
#> user-agent: httr2/1.2.2.9000 r-curl/7.0.0 libcurl/8.5.0
#> 
#> x=1&y=a
```

And
[`req_body_multipart()`](https://httr2.r-lib.org/dev/reference/req_body.md)
uses the multipart encoding which is particularly important when you
need to send larger amounts of data or complete files:

``` r
req |>
  req_body_multipart(x = "1", y = "a") |>
  req_dry_run()
#> POST / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> content-length: 246
#> content-type: multipart/form-data; boundary=------------------------ZELWLaE0m2ffg5i4pC7tbj
#> host: 127.0.0.1:45521
#> user-agent: httr2/1.2.2.9000 r-curl/7.0.0 libcurl/8.5.0
#> 
#> --------------------------ZELWLaE0m2ffg5i4pC7tbj
#> Content-Disposition: form-data; name="x"
#> 
#> 1
#> --------------------------ZELWLaE0m2ffg5i4pC7tbj
#> Content-Disposition: form-data; name="y"
#> 
#> a
#> --------------------------ZELWLaE0m2ffg5i4pC7tbj--
```

If you need to send data encoded in a different form, you can use
[`req_body_raw()`](https://httr2.r-lib.org/dev/reference/req_body.md) to
add the data to the body and set the `Content-Type` header.

## Perform a request and fetch the response

To actually perform a request and fetch the response back from the
server, call
[`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md):

``` r
req <- request(example_url()) |> req_url_path("/json")
resp <- req |> req_perform()
resp
#> <httr2_response>
#> GET http://127.0.0.1:45521/json
#> Status: 200 OK
#> Content-Type: application/json
#> Body: In memory (407 bytes)
```

You can see a simulation of what httr2 actually received with
[`resp_raw()`](https://httr2.r-lib.org/dev/reference/resp_raw.md):

``` r
resp |> resp_raw()
#> HTTP/1.1 200 OK
#> Date: Wed, 14 Jan 2026 19:31:59 GMT
#> Content-Type: application/json
#> Content-Length: 407
#> ETag: "de760e6d"
#> 
#> {
#>   "firstName": "John",
#>   "lastName": "Smith",
#>   "isAlive": true,
#>   "age": 27,
#>   "address": {
#>     "streetAddress": "21 2nd Street",
#>     "city": "New York",
#>     "state": "NY",
#>     "postalCode": "10021-3100"
#>   },
#>   "phoneNumbers": [
#>     {
#>       "type": "home",
#>       "number": "212 555-1234"
#>     },
#>     {
#>       "type": "office",
#>       "number": "646 555-4567"
#>     }
#>   ],
#>   "children": [],
#>   "spouse": null
#> }
```

An HTTP response has a very similar structure to an HTTP request. The
first line gives the version of HTTP used, and a status code that’s
optionally followed by a short description. Then we have the headers,
followed by a blank line, followed by a body. The majority of responses
will have a body, unlike requests.

You can extract data from the response using the `resp_()` functions:

- [`resp_status()`](https://httr2.r-lib.org/dev/reference/resp_status.md)
  returns the status code and
  [`resp_status_desc()`](https://httr2.r-lib.org/dev/reference/resp_status.md)
  returns the description:

  ``` r
  resp |> resp_status()
  #> [1] 200
  resp |> resp_status_desc()
  #> [1] "OK"
  ```

- You can extract all headers with
  [`resp_headers()`](https://httr2.r-lib.org/dev/reference/resp_headers.md)
  or a specific header with
  [`resp_header()`](https://httr2.r-lib.org/dev/reference/resp_headers.md):

  ``` r
  resp |> resp_headers()
  #> <httr2_headers>
  #> Date: Wed, 14 Jan 2026 19:31:59 GMT
  #> Content-Type: application/json
  #> Content-Length: 407
  #> ETag: "de760e6d"
  resp |> resp_header("Content-Length")
  #> [1] "407"
  ```

  Headers are case insensitive:

  ``` r
  resp |> resp_header("ConTEnT-LeNgTH")
  #> [1] "407"
  ```

- You can extract the body in various forms using the `resp_body_*()`
  family of functions. Since this response returns JSON we can use
  [`resp_body_json()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md):

  ``` r
  resp |> resp_body_json() |> str()
  #> List of 8
  #>  $ firstName   : chr "John"
  #>  $ lastName    : chr "Smith"
  #>  $ isAlive     : logi TRUE
  #>  $ age         : int 27
  #>  $ address     :List of 4
  #>   ..$ streetAddress: chr "21 2nd Street"
  #>   ..$ city         : chr "New York"
  #>   ..$ state        : chr "NY"
  #>   ..$ postalCode   : chr "10021-3100"
  #>  $ phoneNumbers:List of 2
  #>   ..$ :List of 2
  #>   .. ..$ type  : chr "home"
  #>   .. ..$ number: chr "212 555-1234"
  #>   ..$ :List of 2
  #>   .. ..$ type  : chr "office"
  #>   .. ..$ number: chr "646 555-4567"
  #>  $ children    : list()
  #>  $ spouse      : NULL
  ```

Responses with status codes 4xx and 5xx are HTTP errors. httr2
automatically turns these into R errors:

``` r
request(example_url()) |>
  req_url_path("/status/404") |>
  req_perform()
#> Error in `req_perform()`:
#> ! HTTP 404 Not Found.

request(example_url()) |>
  req_url_path("/status/500") |>
  req_perform()
#> Error in `req_perform()`:
#> ! HTTP 500 Internal Server Error.
```

This is another important difference to httr, which required that you
explicitly call
[`httr::stop_for_status()`](https://httr.r-lib.org/reference/stop_for_status.html)
to turn HTTP errors into R errors. You can revert to the httr behaviour
with `req_error(req, is_error = \(resp) FALSE)`.

## Control the request process

A number of `req_` functions don’t directly affect the HTTP request but
instead control the overall process of submitting a request and handling
the response. These include:

- [`req_cache()`](https://httr2.r-lib.org/dev/reference/req_cache.md)
  sets up a cache so if repeated requests return the same results, you
  can avoid a trip to the server.

- [`req_throttle()`](https://httr2.r-lib.org/dev/reference/req_throttle.md)
  will automatically add a small delay before each request so you can
  avoid hammering a server with many requests.

- [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md)
  sets up a retry strategy so that if the request either fails or you
  get a transient HTTP error, it’ll automatically retry after a short
  delay.

For more details see their documentation, as well as examples of the
usage in real APIs in the [Wrapping
APIs](https://httr2.r-lib.org/articles/wrapping-apis.html) article.
