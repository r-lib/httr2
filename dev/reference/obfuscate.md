# Obfuscate mildly secret information

Use `obfuscate("value")` to generate a call to `obfuscated()`, which
will unobfuscate the value at the last possible moment. Obfuscated
values only work in limited locations:

- The `secret` argument to
  [`oauth_client()`](https://httr2.r-lib.org/dev/reference/oauth_client.md)

- Elements of the `data` argument to
  [`req_body_form()`](https://httr2.r-lib.org/dev/reference/req_body.md),
  [`req_body_json()`](https://httr2.r-lib.org/dev/reference/req_body.md),
  and
  [`req_body_multipart()`](https://httr2.r-lib.org/dev/reference/req_body.md).

Working together this pair of functions provides a way to obfuscate
mildly confidential information, like OAuth client secrets. The secret
can not be revealed from your inspecting source code, but a skilled R
programmer could figure it out with some effort. The main goal is to
protect against scraping; there's no way for an automated tool to grab
your obfuscated secrets.

## Usage

``` r
obfuscate(x)

obfuscated(x)
```

## Arguments

- x:

  A string to `obfuscate`, or mark as `obfuscated`.

## Value

`obfuscate()` prints the `obfuscated()` call to include in your code.
`obfuscated()` returns an S3 class marking the string as obfuscated so
it can be unobfuscated when needed.

## Examples

``` r
obfuscate("good morning")
#> obfuscated("nRk5-0IuWGWjPUQZAKxVa23NX2wj_GpEkIzH6A")

# Every time you obfuscate you'll get a different value because it
# includes 16 bytes of random data which protects against certain types of
# brute force attack
obfuscate("good morning")
#> obfuscated("bptOnlaAGzZrI_G47gDm4AlKJMhDk8c3Czw0Zg")
```
