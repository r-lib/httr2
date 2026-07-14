# Prune the OAuth token cache

Deletes cached OAuth tokens (from both the current and legacy cache
directories, see
[`oauth_cache_path()`](https://httr2.r-lib.org/reference/oauth_cache_path.md))
that are older than `max_age_days`. This is called automatically when
httr2 is loaded, so you should only need to call it yourself if you want
to prune the cache immediately.

## Usage

``` r
oauth_cache_prune(max_age_days = 30)
```

## Arguments

- max_age_days:

  Delete cached tokens that haven't been modified in this many days.
