# Parse query parameters and/or build a string

`url_query_parse()` parses a query string into a named list;
`url_query_build()` builds a query string from a named list.

## Usage

``` r
url_query_parse(query)

url_query_build(query, .multi = c("error", "comma", "pipe", "explode"))
```

## Arguments

- query:

  A string, when parsing; a named list when building.

- .multi:

  Controls what happens when a value is a vector:

  - `"error"`, the default, throws an error.

  - `"comma"`, separates values with a `,`, e.g. `?x=1,2`.

  - `"pipe"`, separates values with a `|`, e.g. `?x=1|2`.

  - `"explode"`, turns each element into its own parameter, e.g.
    `?x=1&x=2`

  If none of these options work for your needs, you can instead supply a
  function that takes a character vector of argument values and returns
  a a single string.

## Examples

``` r
str(url_query_parse("a=1&b=2"))
#> List of 2
#>  $ a: chr "1"
#>  $ b: chr "2"

url_query_build(list(x = 1, y = "z"))
#> [1] "x=1&y=z"
url_query_build(list(x = 1, y = 1:2), .multi = "explode")
#> [1] "x=1&y=1&y=2"
```
