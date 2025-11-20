# Translate curl syntax to httr2

The curl command line tool is commonly used to demonstrate HTTP APIs and
can easily be generated from [browser developer
tools](https://everything.curl.dev/cmdline/copyas.html).
`curl_translate()` saves you the pain of manually translating these
calls by implementing a partial, but frequently used, subset of curl
options. Use `curl_help()` to see the supported options, and
`curl_translate()` to translate a curl invocation copy and pasted from
elsewhere.

Inspired by [curlconverter](https://github.com/hrbrmstr/curlconverter)
written by [Bob Rudis](https://rud.is/b/).

## Usage

``` r
curl_translate(cmd, simplify_headers = TRUE)

curl_help()
```

## Arguments

- cmd:

  Call to curl. If omitted and the clipr package is installed, will be
  retrieved from the clipboard.

- simplify_headers:

  Remove typically unimportant headers included when copying a curl
  command from the browser. This includes:

  - `sec-fetch-*`

  - `sec-ch-ua*`

  - `referer`, `pragma`, `connection`

## Value

A string containing the translated httr2 code. If the input was copied
from the clipboard, the translation will be copied back to the
clipboard.

## Examples

``` r
curl_translate("curl http://example.com")
#> request("http://example.com/") |>
#>   req_perform()
curl_translate("curl http://example.com -X DELETE")
#> request("http://example.com/") |>
#>   req_method("DELETE") |>
#>   req_perform()
curl_translate("curl http://example.com --header A:1 --header B:2")
#> request("http://example.com/") |>
#>   req_headers(
#>     A = "1",
#>     B = "2",
#>   ) |>
#>   req_perform()
curl_translate("curl http://example.com --verbose")
#> request("http://example.com/") |>
#>   req_perform(verbosity = 1)
```
