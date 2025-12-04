# Tools for working with lists of responses

These functions provide a basic toolkit for operating with lists of
responses and possibly errors, as returned by
[`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md),
[`req_perform_sequential()`](https://httr2.r-lib.org/dev/reference/req_perform_sequential.md)
and
[`req_perform_iterative()`](https://httr2.r-lib.org/dev/reference/req_perform_iterative.md).

- `resps_successes()` returns a list of successful responses.

- `resps_failures()` returns a list of failed responses (i.e. errors).

- `resps_requests()` returns the list of requests that corresponds to
  each request.

- `resps_data()` returns all the data in a single vector or data frame.
  It requires the vctrs package to be installed.

## Usage

``` r
resps_successes(resps)

resps_failures(resps)

resps_requests(resps)

resps_data(resps, resp_data)
```

## Arguments

- resps:

  A list of responses (possibly including errors).

- resp_data:

  A function that takes a response (`resp`) and returns the data found
  inside that response as a vector or data frame.

  NB: If you're using
  [`resp_body_raw()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md),
  you're likely to want to wrap its output in
  [`list()`](https://rdrr.io/r/base/list.html) to avoid combining all
  the bodies into a single raw vector, e.g.
  `resps |> resps_data(\(resp) list(resp_body_raw(resp)))`.

## Examples

``` r
reqs <- list(
  request(example_url()) |> req_url_path("/ip"),
  request(example_url()) |> req_url_path("/user-agent"),
  request(example_url()) |> req_template("/status/:status", status = 404),
  request("INVALID")
)
resps <- req_perform_parallel(reqs, on_error = "continue")

# find successful responses
resps |> resps_successes()
#> [[1]]
#> <httr2_response>
#> GET http://127.0.0.1:36377/ip
#> Status: 200 OK
#> Content-Type: application/json
#> Body: In memory (27 bytes)
#> 
#> [[2]]
#> <httr2_response>
#> GET http://127.0.0.1:36377/user-agent
#> Status: 200 OK
#> Content-Type: application/json
#> Body: In memory (65 bytes)
#> 

# collect all their data
resps |>
  resps_successes() |>
  resps_data(\(resp) resp_body_json(resp))
#> $origin
#> [1] "127.0.0.1"
#> 
#> $`user-agent`
#> [1] "httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0"
#> 

# find requests corresponding to failure responses
resps |>
  resps_failures() |>
  resps_requests()
#> [[1]]
#> <httr2_request>
#> GET http://127.0.0.1:36377/status/404
#> Body: empty
#> 
#> [[2]]
#> <httr2_request>
#> GET INVALID
#> Body: empty
#> 
```
