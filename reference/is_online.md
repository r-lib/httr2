# Is your computer currently online?

This function uses some cheap heuristics to determine if your computer
is currently online. It's a simple wrapper around
[`curl::has_internet()`](https://jeroen.r-universe.dev/curl/reference/nslookup.html)
exported from httr2 for convenience.

## Usage

``` r
is_online()
```

## Examples

``` r
is_online()
#> [1] TRUE
```
