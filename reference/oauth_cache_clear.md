# Clear OAuth cache

Use this function to clear cached credentials.

## Usage

``` r
oauth_cache_clear(client, cache_disk = FALSE, cache_key = NULL)
```

## Arguments

- client:

  An
  [`oauth_client()`](https://httr2.r-lib.org/reference/oauth_client.md).

- cache_disk:

  Should the access token be cached on disk? This reduces the number of
  times that you need to re-authenticate at the cost of storing access
  credentials on disk.

  Learn more in <https://httr2.r-lib.org/articles/oauth.html>.

- cache_key:

  If you want to cache multiple tokens per app, use this key to
  disambiguate them.
