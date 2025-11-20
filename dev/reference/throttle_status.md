# Display internal throttle status

Sometimes useful for debugging.

## Usage

``` r
throttle_status()
```

## Value

A data frame with three columns:

- The `realm`.

- Number of `tokens` remaining in the bucket.

- Time `to_wait` in seconds for next token.
