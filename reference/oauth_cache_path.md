# httr2 OAuth cache location

When opted-in to, httr2 caches OAuth tokens in this directory. By
default, it uses a OS-standard cache directory, but, if needed, you can
override the location by setting the `HTTR2_OAUTH_CACHE` env var.

## Usage

``` r
oauth_cache_path()
```
