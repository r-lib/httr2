# Extract response content type and encoding

`resp_content_type()` returns the just the type and subtype of the from
the `Content-Type` header. If `Content-Type` is not provided; it returns
`NA`. Used by
[`resp_body_json()`](https://httr2.r-lib.org/reference/resp_body_raw.md),
[`resp_body_html()`](https://httr2.r-lib.org/reference/resp_body_raw.md),
and
[`resp_body_xml()`](https://httr2.r-lib.org/reference/resp_body_raw.md).

`resp_encoding()` returns the likely character encoding of text types,
as parsed from the `charset` parameter of the `Content-Type` header. If
that header is not found, not valid, or no charset parameter is found,
returns `UTF-8`. Used by
[`resp_body_string()`](https://httr2.r-lib.org/reference/resp_body_raw.md).

## Usage

``` r
resp_content_type(resp)

resp_encoding(resp)
```

## Arguments

- resp:

  A httr2 [response](https://httr2.r-lib.org/reference/response.md)
  object, created by
  [`req_perform()`](https://httr2.r-lib.org/reference/req_perform.md).

## Value

A string. If no content type is specified `resp_content_type()` will
return a character `NA`; if no encoding is specified, `resp_encoding()`
will return `"UTF-8"`.

## Examples

``` r
resp <- response(headers = "Content-type: text/html; charset=utf-8")
resp |> resp_content_type()
#> [1] "text/html"
resp |> resp_encoding()
#> [1] "utf-8"

# No Content-Type header
resp <- response()
resp |> resp_content_type()
#> [1] NA
resp |> resp_encoding()
#> [1] "UTF-8"
```
