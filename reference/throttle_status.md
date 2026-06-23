# Display internal throttle status

Sometimes useful for debugging.

## Usage

``` r
throttle_status()
```

## Value

A data frame with one row per token bucket and four columns:

- The `realm`.

- The `capacity` of the bucket.

- Number of `tokens` remaining in the bucket.

- Time `to_wait` in seconds for next token.
