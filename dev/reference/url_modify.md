# Modify a URL

Use `url_modify()` to modify any component of the URL,
`url_modify_relative()` to modify with a relative URL, or
`url_modify_query()` to modify individual query parameters.

For `url_modify()`, components that aren't specified in the function
call will be left as is; components set to `NULL` will be removed, and
all other values will be updated. Note that removing `scheme` or
`hostname` will create a relative URL.

## Usage

``` r
url_modify(
  url,
  scheme = as_is,
  hostname = as_is,
  username = as_is,
  password = as_is,
  port = as_is,
  path = as_is,
  query = as_is,
  fragment = as_is
)

url_modify_relative(url, relative_url)

url_modify_query(
  .url,
  ...,
  .multi = c("error", "comma", "pipe", "explode"),
  .space = c("percent", "form")
)
```

## Arguments

- url, .url:

  A string or [parsed
  URL](https://httr2.r-lib.org/dev/reference/url_parse.md).

- scheme:

  The scheme, typically either `http` or `https`.

- hostname:

  The hostname, e.g., `www.google.com` or `posit.co`.

- username, password:

  Username and password to embed in the URL. Not generally recommended
  but needed for some legacy applications.

- port:

  An integer port number.

- path:

  The path, e.g., `/search`. Paths must start with `/`, so this will be
  automatically added if omitted.

- query:

  Either a query string or a named list of query components.

- fragment:

  The fragment, e.g., `#section-1`.

- relative_url:

  A relative URL to append to the base URL.

- ...:

  \<[`dynamic-dots`](https://rlang.r-lib.org/reference/dyn-dots.html)\>
  Name-value pairs that define query parameters. Each value must be
  either an atomic vector or `NULL` (which removes the corresponding
  parameters). If you want to opt out of escaping, wrap strings in
  [`I()`](https://rdrr.io/r/base/AsIs.html).

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

- .space:

  How should spaces in query params be escaped? The default, "percent",
  uses standard percent encoding (i.e. `%20`), but you can opt-in to
  "form" encoding, which uses `+` instead.

## Value

An object of the same type as `url`.

## See also

Other URL manipulation:
[`url_build()`](https://httr2.r-lib.org/dev/reference/url_build.md),
[`url_parse()`](https://httr2.r-lib.org/dev/reference/url_parse.md)

## Examples

``` r
url_modify("http://hadley.nz", path = "about")
#> [1] "http://hadley.nz/about"
url_modify("http://hadley.nz", scheme = "https")
#> [1] "https://hadley.nz/"
url_modify("http://hadley.nz/abc", path = "/cde")
#> [1] "http://hadley.nz/cde"
url_modify("http://hadley.nz/abc", path = "")
#> [1] "http://hadley.nz/"
url_modify("http://hadley.nz?a=1", query = "b=2")
#> [1] "http://hadley.nz/?b=2"
url_modify("http://hadley.nz?a=1", query = list(c = 3))
#> [1] "http://hadley.nz/?c=3"

url_modify_query("http://hadley.nz?a=1&b=2", c = 3)
#> [1] "http://hadley.nz/?a=1&b=2&c=3"
url_modify_query("http://hadley.nz?a=1&b=2", b = NULL)
#> [1] "http://hadley.nz/?a=1"
url_modify_query("http://hadley.nz?a=1&b=2", a = 100)
#> [1] "http://hadley.nz/?b=2&a=100"

url_modify_relative("http://hadley.nz/a/b/c.html", "/d.html")
#> [1] "http://hadley.nz/d.html"
url_modify_relative("http://hadley.nz/a/b/c.html", "d.html")
#> [1] "http://hadley.nz/a/b/d.html"
url_modify_relative("http://hadley.nz/a/b/c.html", "../d.html")
#> [1] "http://hadley.nz/a/d.html"
```
