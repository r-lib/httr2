# Parse a URL into its component pieces

`url_parse()` parses a URL into its component parts, powered by
[`curl::curl_parse_url()`](https://jeroen.r-universe.dev/curl/reference/curl_parse_url.html).
The parsing algorithm follows the specifications detailed in [RFC
3986](https://datatracker.ietf.org/doc/html/rfc3986).

## Usage

``` r
url_parse(url, base_url = NULL)
```

## Arguments

- url:

  A string containing the URL to parse.

- base_url:

  Use this as a parent, if `url` is a relative URL.

## Value

An S3 object of class `httr2_url` with the following components:
`scheme`, `hostname`, `username`, `password`, `port`, `path`, `query`,
and `fragment`.

## See also

Other URL manipulation:
[`url_build()`](https://httr2.r-lib.org/dev/reference/url_build.md),
[`url_modify()`](https://httr2.r-lib.org/dev/reference/url_modify.md)

## Examples

``` r
url_parse("http://google.com/")
#> <httr2_url> http://google.com/
#> * scheme: http
#> * hostname: google.com
#> * path: /
url_parse("http://google.com:80/")
#> <httr2_url> http://google.com:80/
#> * scheme: http
#> * hostname: google.com
#> * port: 80
#> * path: /
url_parse("http://google.com:80/?a=1&b=2")
#> <httr2_url> http://google.com:80/?a=1&b=2
#> * scheme: http
#> * hostname: google.com
#> * port: 80
#> * path: /
#> * query:
#>   * a: 1
#>   * b: 2
url_parse("http://username@google.com:80/path;test?a=1&b=2#40")
#> <httr2_url> http://username@google.com:80/path%3Btest?a=1&b=2#40
#> * scheme: http
#> * hostname: google.com
#> * username: username
#> * port: 80
#> * path: /path;test
#> * query:
#>   * a: 1
#>   * b: 2
#> * fragment: 40

# You can parse a relative URL if you also provide a base url
url_parse("foo", "http://google.com/bar/")
#> <httr2_url> http://google.com/bar/foo
#> * scheme: http
#> * hostname: google.com
#> * path: /bar/foo
url_parse("..", "http://google.com/bar/")
#> <httr2_url> http://google.com/
#> * scheme: http
#> * hostname: google.com
#> * path: /
```
