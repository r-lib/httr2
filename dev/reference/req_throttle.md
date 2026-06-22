# Rate limit a request by automatically adding a delay

Use `req_throttle()` to ensure that repeated calls to
[`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
never exceed a specified rate.

Throttling is implemented using a "token bucket", which steadily fills
up to a maximum of `capacity` tokens over `fill_time_s`. Each time you
make a request, it takes a token out of the bucket, and if the bucket is
empty, the request will wait until the bucket refills. This ensures that
you never make more than `capacity` requests in `fill_time_s`, but you
can make requests more quickly if the bucket is full. For example, if
you have `capacity = 10` and `fill_time_s = 60`, you can make 10
requests without waiting, but the next request will wait 60 seconds.
This gives the same average throttling rate as the previous approach,
but gives you much better performance if you're only making a small
number of requests.

Some APIs enforce multiple rate limits simultaneously, e.g. no more than
4 requests per second *and* no more than 200 requests per hour. You can
handle this by supplying a vector to `capacity` and `fill_time_s`: this
creates one token bucket per limit, and each request must satisfy all of
them. This lets you make quick bursts of requests while still respecting
longer term limits.

## Usage

``` r
req_throttle(req, rate, capacity, fill_time_s = 60, realm = NULL)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- rate:

  For backwards compatibility, you can still specify the `rate`, which
  is converted to `capacity` by multiplying by `fill_time_s`. However,
  we recommend using `capacity` and `fill_time_s` as it gives more
  control.

- capacity:

  The size of the bucket, i.e. the maximum number of tokens that can
  accumulate. To enforce multiple rate limits at once, supply a vector
  of capacities (one per limit); `capacity` and `fill_time_s` are
  recycled to a common length.

- fill_time_s:

  Time in seconds to fill the capacity. Defaults to 60s.

- realm:

  A string that uniquely identifies the throttle pool to use (throttling
  limits always apply *per pool*). If not supplied, defaults to the
  hostname of the request.

## Value

A modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md).

## See also

[`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md) for
another way of handling rate-limited APIs.

## Examples

``` r
# Ensure we never send more than 30 requests a minute
req <- request(example_url()) |>
  req_throttle(capacity = 30, fill_time_s = 60)

resp <- req_perform(req)
throttle_status()
#>       realm capacity tokens to_wait
#> 1 127.0.0.1       30     29       0
resp <- req_perform(req)
throttle_status()
#>       realm capacity tokens to_wait
#> 1 127.0.0.1       30     28       0

# Enforce multiple limits at once: no more than 10 requests every 1s
# and no more than 100 requests every 60s
req <- request(example_url()) |>
  req_throttle(capacity = c(10, 100), fill_time_s = c(1, 60))
resp <- req_perform(req)
throttle_status()
#>       realm capacity tokens to_wait
#> 1 127.0.0.1       10      9       0
#> 2 127.0.0.1      100     99       0
```
