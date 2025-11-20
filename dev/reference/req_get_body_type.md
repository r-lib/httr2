# Get request body

This pair of functions gives you sufficient information to capture the
body of a request, and recreate, if needed. httr2 currently supports
seven possible body types:

- empty: no body.

- raw: created by
  [`req_body_raw()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  with a raw vector.

- string: created by
  [`req_body_raw()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  with a string.

- file: created by
  [`req_body_file()`](https://httr2.r-lib.org/dev/reference/req_body.md).

- json: created by
  [`req_body_json()`](https://httr2.r-lib.org/dev/reference/req_body.md)/[`req_body_json_modify()`](https://httr2.r-lib.org/dev/reference/req_body.md).

- form: created by
  [`req_body_form()`](https://httr2.r-lib.org/dev/reference/req_body.md).

- multipart: created by
  [`req_body_multipart()`](https://httr2.r-lib.org/dev/reference/req_body.md).

## Usage

``` r
req_get_body_type(req)

req_get_body(req, obfuscated = c("remove", "redact", "reveal"))
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

## Examples

``` r
req <- request(example_url())
req |> req_body_raw("abc") |> req_get_body_type()
#> [1] "string"
req |> req_body_file(system.file("DESCRIPTION")) |> req_get_body_type()
#> [1] "file"
req |> req_body_json(list(x = 1, y = 2)) |> req_get_body_type()
#> [1] "json"
req |> req_body_form(x = 1, y = 2) |> req_get_body_type()
#> [1] "form"
req |> req_body_multipart(x = "x", y = "y") |> req_get_body_type()
#> [1] "multipart"
```
