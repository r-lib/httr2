# Extract timing data

The underlying curl library measures how long different components of
the request take to complete. This function retrieves that information.

## Usage

``` r
resp_timing(resp)
```

## Arguments

- resp:

  A httr2 [response](https://httr2.r-lib.org/dev/reference/response.md)
  object, created by
  [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md).

## Value

Named numeric vector of timing information. The names of the elements in
this vector correspond to the names used in [libcurl's
`curl_easy_getinfo()`
API](https://curl.se/libcurl/c/curl_easy_getinfo.html). The most useful
component is likely `"total"` (corresponding to `CURLINFO_TOTAL_TIME`),
the overall time in seconds to complete the request including any
redirects followed.

## Examples

``` r
req <- request(example_url())
resp <- req_perform(req)
resp_timing(resp)
#>      redirect    namelookup       connect   pretransfer starttransfer 
#>      0.000108      0.000023      0.000084      0.000188      0.002664 
#>         total 
#>      0.003084 
```
