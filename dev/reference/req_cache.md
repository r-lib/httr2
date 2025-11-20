# Automatically cache requests

Use `req_cache()` to automatically cache HTTP requests. Most API
requests are not cacheable, but static files often are.

`req_cache()` caches responses to GET requests that have status code 200
and at least one of the standard caching headers (e.g. `Expires`,
`Etag`, `Last-Modified`, `Cache-Control`), unless caching has been
expressly prohibited with `Cache-Control: no-store`. Typically, a
request will still be sent to the server to check that the cached value
is still up-to-date, but it will not need to re-download the body value.

To learn more about HTTP caching, I recommend the MDN article [HTTP
caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching).

## Usage

``` r
req_cache(
  req,
  path,
  use_on_error = FALSE,
  debug = getOption("httr2_cache_debug", FALSE),
  max_age = Inf,
  max_n = Inf,
  max_size = 1024^3
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- path:

  Path to cache directory. Will be created automatically if it does not
  exist.

  For quick and easy caching within a session, you can use
  [`tempfile()`](https://rdrr.io/r/base/tempfile.html). To cache
  requests within a package, you can use something like
  `file.path(tools::R_user_dir("pkgdown", "cache"), "httr2")`.

  httr2 doesn't provide helpers to manage the cache, but if you want to
  empty it, you can use something like
  `unlink(dir(cache_path, full.names = TRUE))`.

- use_on_error:

  If the request errors, and there's a cache response, should
  [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
  return that instead of generating an error?

- debug:

  When `TRUE` will emit useful messages telling you about cache hits and
  misses. This can be helpful to understand whether or not caching is
  actually doing anything for your use case.

- max_n, max_age, max_size:

  Automatically prune the cache by specifying one or more of:

  - `max_age`: to delete files older than this number of seconds.

  - `max_n`: to delete files (from oldest to newest) to preserve at most
    this many files.

  - `max_size`: to delete files (from oldest to newest) to preserve at
    most this many bytes.

  The cache pruning is performed at most once per minute.

## Value

A modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md).

## Examples

``` r
# GitHub uses HTTP caching for all raw files.
url <- paste0(
  "https://raw.githubusercontent.com/allisonhorst/palmerpenguins/",
  "master/inst/extdata/penguins.csv"
)
# Here I set debug = TRUE so you can see what's happening
req <- request(url) |> req_cache(tempdir(), debug = TRUE)

# First request downloads the data
resp <- req |> req_perform()
#> Pruning cache
#> Saving response to cache "d5d1ddd7f99f55dbc920c63f942804c0"

# Second request retrieves it from the cache
resp <- req |> req_perform()
#> Found url in cache "d5d1ddd7f99f55dbc920c63f942804c0"
#> Cached value is fresh; using response from cache
```
