# Parse link URL from a response

Parses URLs out of the the `Link` header as defined by [RFC
8288](https://datatracker.ietf.org/doc/html/rfc8288).

## Usage

``` r
resp_link_url(resp, rel)
```

## Arguments

- resp:

  A httr2 [response](https://httr2.r-lib.org/dev/reference/response.md)
  object, created by
  [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md).

- rel:

  The "link relation type" value for which to retrieve a URL.

## Value

Either a string providing a URL, if the specified `rel` exists, or
`NULL` if not.

## Examples

``` r
# Simulate response from GitHub code search
resp <- response(headers = paste0("Link: ",
  '<https://api.github.com/search/code?q=addClass+user%3Amozilla&page=2>; rel="next",',
  '<https://api.github.com/search/code?q=addClass+user%3Amozilla&page=34>; rel="last"'
))

resp_link_url(resp, "next")
#> [1] "https://api.github.com/search/code?q=addClass+user%3Amozilla&page=2"
resp_link_url(resp, "last")
#> [1] "https://api.github.com/search/code?q=addClass+user%3Amozilla&page=34"
resp_link_url(resp, "prev")
#> NULL
```
