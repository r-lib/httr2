# Add a progress bar to long downloads or uploads

When uploading or downloading a large file, it's often useful to provide
a progress bar so that you know how long you have to wait.

## Usage

``` r
req_progress(req, type = c("down", "up"))
```

## Arguments

- req:

  A [request](https://httr2.r-lib.org/reference/request.md).

- type:

  Type of progress to display: either number of bytes uploaded or
  downloaded.

## Examples

``` r
req <- request("https://r4ds.s3.us-west-2.amazonaws.com/seattle-library-checkouts.csv") |>
  req_progress()

if (FALSE) { # \dontrun{
path <- tempfile()
req |> req_perform(path = path)
} # }
```
