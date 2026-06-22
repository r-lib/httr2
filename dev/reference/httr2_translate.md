# Translate a httr2 request to a curl command

Convert a httr2 request object to an approximate curl command line call.
This is useful for debugging, for sharing a request with someone who
doesn't use R, or for handing off to another tool.

## Usage

``` r
httr2_translate(req, obfuscated = c("redact", "reveal"))
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- obfuscated:

  Form and JSON bodies can contain
  [obfuscated](https://httr2.r-lib.org/dev/reference/obfuscate.md)
  values. This argument control what happens to them: should they be
  removed, redacted, or revealed.

## Value

A string containing the curl command.

## See also

[`curl_translate()`](https://httr2.r-lib.org/dev/reference/curl_translate.md)
to translate in the other direction.

## Examples

``` r
# Basic GET request
request("https://httpbin.org/get") |>
  httr2_translate()
#> curl https://httpbin.org/get \
#>   --location \
#>   --user-agent 'httr2/1.2.2.9000 r-curl/7.1.0 libcurl/8.5.0'

# POST with JSON body
request("https://httpbin.org/post") |>
  req_body_json(list(name = "value")) |>
  httr2_translate()
#> curl https://httpbin.org/post \
#>   --header 'Content-Type: application/json' \
#>   --location \
#>   --user-agent 'httr2/1.2.2.9000 r-curl/7.1.0 libcurl/8.5.0' \
#>   --data '{"name":"value"}'

# Secrets are redacted by default, but can be revealed
request("https://example.com") |>
  req_headers_redacted(Authorization = "secret") |>
  httr2_translate(obfuscated = "reveal")
#> curl https://example.com \
#>   --header 'Authorization: secret' \
#>   --location \
#>   --user-agent 'httr2/1.2.2.9000 r-curl/7.1.0 libcurl/8.5.0'
```
