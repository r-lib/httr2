# Wrapping APIs

A common use for httr2 is wrapping up a useful API and exposing it in an
R package where each API endpoint (i.e. a URL with parameters) becomes
an R function with documented arguments. This vignette will show you
how, starting with a very simple API that doesn’t need authentication,
then slowly working up in complexity. Along the way, you’ll learn about
how to:

- Expose important details from HTTP errors in R errors.

- Handle various types of authentication.

- Consistently throttle the rate of requests or dynamically respond to
  rate limiting headers sent by the server.

I assume you’re familiar with the basics of building a package. If not,
you might want to read the “[The Whole
Game](https://r-pkgs.org/whole-game.html)” chapter of [R
packages](https://r-pkgs.org) first.

``` r
library(httr2)
```

## Faker API

We’ll start with a very simple API, [faker API](https://fakerapi.it/en),
which provides a collection of techniques for generating fake data.
Before we start writing the sort of functions that you might put in a
package, we’ll perform a request just to see how the basics work:

``` r
# We start by creating a request that uses the base API url
req <- request("https://fakerapi.it/api/v1")
resp <- req |>
  # Then we add on the images path
  req_url_path_append("images") |>
  # Add query parameters _width and _quantity
  req_url_query(`_width` = 380, `_quantity` = 1) |>
  req_perform()

# The result comes back as JSON
resp |> resp_body_json() |> str()
#> List of 6
#>  $ status: chr "OK"
#>  $ code  : int 200
#>  $ locale: chr "en_US"
#>  $ seed  : NULL
#>  $ total : int 1
#>  $ data  :List of 1
#>   ..$ :List of 3
#>   .. ..$ title      : chr "Sapiente quia qui et ea."
#>   .. ..$ description: chr "Explicabo vel et in ut nam molestiae sed assumenda. Maxime qui maiores rerum recusandae quis. Voluptatum ullam "| __truncated__
#>   .. ..$ url        : chr "https://picsum.photos/380/480"
```

### Errors

It’s always worth a little early experimentation to see if we get any
useful information from errors. The httr2 defaults get in your way here,
because if you retrieve an unsuccessful HTTP response, you automatically
get an error that prevents you from further inspecting the body:

``` r
req |>
  req_url_path_append("invalid") |>
  req_perform()
#> Error in `req_perform()`:
#> ! HTTP 400 Bad Request.
```

However, you can access the last response (successful or not) with
[`last_response()`](https://httr2.r-lib.org/dev/reference/last_response.md):

``` r
resp <- last_response()
resp |> resp_body_json()
#> $message
#> [1] "Resource invalid not supported in version v1"
```

It doesn’t look like there’s anything useful there. Sometimes useful
info is returned in the headers, so let’s check:

``` r
resp |> resp_headers()
#> <httr2_headers>
#> Server: nginx
#> Content-Type: application/json
#> Transfer-Encoding: chunked
#> Connection: keep-alive
#> X-Powered-By: PHP/8.3.8
#> Cache-Control: no-cache, private
#> Date: Fri, 05 Dec 2025 16:52:36 GMT
#> X-RateLimit-Limit: 60
#> X-RateLimit-Remaining: 56
#> Access-Control-Allow-Origin: *
```

It doesn’t look like we’re getting any more useful information, so we
can leave the
[`req_error()`](https://httr2.r-lib.org/dev/reference/req_error.md)
default as is. We’ll have another go later with an API that does provide
more details.

### User agent

If you’re wrapping this code into a package, it’s considered polite to
set a user agent, so that, if your package accidentally does something
horribly wrong, the developers of the website can figure out who to
reach out to. You can do this with the
[`req_user_agent()`](https://httr2.r-lib.org/dev/reference/req_user_agent.md)
function:

``` r
req |>
  req_user_agent("my_package_name (http://my.package.web.site)") |>
  req_dry_run()
#> GET /api/v1 HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> host: fakerapi.it
#> user-agent: my_package_name (http://my.package.web.site)
```

### Core request function

Once you’ve made a few successful requests, it’s worth seeing if you can
figure out the general pattern so you can wrap it up into a function
that will become the core of your package.

For faker, I spent a little time with the
[documentation](https://fakerapi.it/en#basic-usage) noting some
commonalities:

- Every URL is of the form `https://fakerapi.it/api/v1/{resource}`, and
  data is passed to the resource with query parameters. All parameters
  start with `_`.

- Every resource has three common query parameters: `_locale`,
  `_quantity`, and `_seed`.

- All endpoints return JSON data.

This led me to construct the following function:

``` r
faker <- function(resource, ..., quantity = 1, locale = "en_US", seed = NULL) {
  params <- list(
    ...,
    quantity = quantity,
    locale = locale,
    seed = seed
  )
  names(params) <- paste0("_", names(params))

  request("https://fakerapi.it/api/v1") |>
    req_url_path_append(resource) |>
    req_url_query(!!!params) |>
    req_user_agent("my_package_name (http://my.package.web.site)") |>
    req_perform() |>
    resp_body_json()
}

str(faker("images", width = 300))
#> List of 6
#>  $ status: chr "OK"
#>  $ code  : int 200
#>  $ locale: chr "en_US"
#>  $ seed  : NULL
#>  $ total : int 1
#>  $ data  :List of 1
#>   ..$ :List of 3
#>   .. ..$ title      : chr "Sint et est blanditiis."
#>   .. ..$ description: chr "Et ea nisi quidem aspernatur. Beatae velit sed nostrum sint vel voluptas. Maxime molestias neque quia autem cor"| __truncated__
#>   .. ..$ url        : chr "https://picsum.photos/300/480"
```

I’ve made a few important choices here:

- I’ve decided to supply default values for the `quantity` and `locale`
  parameters. This makes my function easier to demo in this vignette.

- I’ve used a default of `NULL` for the `seed` argument.
  [`req_url_query()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  will automatically drop `NULL` arguments so this means that no default
  value is sent to the API, but when you read the function definition
  you can still see that `seed` is accepted.

- I automatically prefix all query parameters with `_` because argument
  names starting with `_` are hard to type in R.

- My function generates the request, performs it, and extracts the body
  of the response. This works well for simple cases, but for more
  complex APIs you might want to return a request object that can be
  modified before being performed.

I also used one cool trick:
[`req_url_query()`](https://httr2.r-lib.org/dev/reference/req_url.md)
uses [dynamic dots](https://rlang.r-lib.org/reference/dyn-dots.html), so
we can use `!!!` to convert (e.g.)
`` req_url_query(req, !!!list(`_quantity` = 1, `_locale` = "en_US")) ``
into `` req_url_query(req, `_quantity` = 1, `_locale` = "en_US") ``.

### Wrapping individual endpoints

`faker()` is quite general — it’s a good tool for the package developer
because you can read the faker documentation and translate it to a
function call. But it’s not very friendly for the package user who might
not know anything about web APIs. So typically the next step in the
process is to wrap up some individual endpoints with their own
functions.

For example, let’s take the `persons` endpoint which has three
additional parameters: `gender` (male or female), `birthday_start`, and
`birthday_end`. A simple wrapper would start something like this:

``` r
faker_person <- function(gender = NULL, birthday_start = NULL, birthday_end = NULL, quantity = 1, locale = "en_US", seed = NULL) {
  faker(
    "persons",
    gender = gender,
    birthday_start = birthday_start,
    birthday_end = birthday_end,
    quantity = quantity,
    locale = locale,
    seed = seed
  )
}
str(faker_person("male"))
#> List of 6
#>  $ status: chr "OK"
#>  $ code  : int 200
#>  $ locale: chr "en_US"
#>  $ seed  : NULL
#>  $ total : int 1
#>  $ data  :List of 1
#>   ..$ :List of 10
#>   .. ..$ id       : int 1
#>   .. ..$ firstname: chr "Jon"
#>   .. ..$ lastname : chr "Gusikowski"
#>   .. ..$ email    : chr "regan55@hotmail.com"
#>   .. ..$ phone    : chr "+17378507412"
#>   .. ..$ birthday : chr "2020-04-03"
#>   .. ..$ gender   : chr "male"
#>   .. ..$ address  :List of 10
#>   .. .. ..$ id            : int 1
#>   .. .. ..$ street        : chr "2411 Rosenbaum Islands"
#>   .. .. ..$ streetName    : chr "Sydnee Valley"
#>   .. .. ..$ buildingNumber: chr "9819"
#>   .. .. ..$ city          : chr "Port Nyasia"
#>   .. .. ..$ zipcode       : chr "04971-9382"
#>   .. .. ..$ country       : chr "Brazil"
#>   .. .. ..$ country_code  : chr "BR"
#>   .. .. ..$ latitude      : num 23.3
#>   .. .. ..$ longitude     : num 101
#>   .. ..$ website  : chr "http://feeney.com"
#>   .. ..$ image    : chr "http://placeimg.com/640/480/people"
```

We could make it more user friendly by checking the input types, and
returning the result as a tibble. I did a quick and dirty conversion
using purrr; depending on your needs you could use base R code or
`tidyr::hoist()`.

``` r
library(purrr)

faker_person <- function(gender = NULL, birthday_start = NULL, birthday_end = NULL, quantity = 1, locale = "en_US", seed = NULL) {
  if (!is.null(gender)) {
    gender <- match.arg(gender, c("male", "female"))
  }
  if (!is.null(birthday_start)) {
    if (!inherits(birthday_start, "Date")) {
      stop("`birthday_start` must be a date")
    }
    birthday_start <- format(birthday_start, "%Y-%m-%d")
  }
  if (!is.null(birthday_end)) {
    if (!inherits(birthday_end, "Date")) {
      stop("`birthday_end` must be a date")
    }
    birthday_end <- format(birthday_end, "%Y-%m-%d")
  }

  json <- faker(
    "persons",
    gender = gender,
    birthday_start = birthday_start,
    birthday_end = birthday_end,
    quantity = quantity,
    locale = locale,
    seed = seed
  )

  tibble::tibble(
    firstname = map_chr(json$data, "firstname"),
    lastname = map_chr(json$data, "lastname"),
    email = map_chr(json$data, "email"),
    gender = map_chr(json$data, "gender")
  )
}
faker_person("male", quantity = 5)
#> # A tibble: 5 × 4
#>   firstname lastname email                     gender
#>   <chr>     <chr>    <chr>                     <chr> 
#> 1 Kennedy   Cronin   walsh.shirley@sanford.net male  
#> 2 Greg      Lowe     watsica.garnet@yahoo.com  male  
#> 3 Cortez    Zemlak   hmorar@halvorson.com      male  
#> 4 Sterling  Okuneva  alejandra99@ullrich.com   male  
#> 5 Francisco Brakus   pritchie@rutherford.com   male
```

The next steps would be to export and document this function; I’ll leave
that up to you.

## Secret management

We need to take a quick break from APIs to talk about secrets. Secrets
are important, because every API (except for very simple APIs like
faker) is going to require that you identify yourself in some way,
typically with an API key or a token. And even if you plan to require
your users to supply this information, you’ll still need to record your
own credentials in order to test your own package.

This system described below is likely to be overkill if you have one
secret that only needs to be shared in a couple of places: you can just
put it in your `.Renviron` and access it with
[`Sys.getenv()`](https://rdrr.io/r/base/Sys.getenv.html). But you will
probably accumulate more secrets over time, and you’ll need to figure
out how to share them with other people and other computers, so I think
spending a little time to understand this system and set up it for your
package will pay off in the long term.

### Basics

httr2 provides
[`secret_encrypt()`](https://httr2.r-lib.org/dev/reference/secrets.md)
and
[`secret_decrypt()`](https://httr2.r-lib.org/dev/reference/secrets.md)
to scramble secrets so that you can include them in your public source
code without worrying that others can read them. There are three basic
steps to this process:

1.  You create an **encryption** key with
    [`secret_make_key()`](https://httr2.r-lib.org/dev/reference/secrets.md)
    that is used to scramble and descramble secrets using symmetric
    cryptography:

    ``` r
    key <- secret_make_key()
    key
    #> [1] "RyabvsG7ajDOsqZQ_LeRrA"
    ```

    (Note that
    [`secret_make_key()`](https://httr2.r-lib.org/dev/reference/secrets.md)
    uses a cryptographically secure random number generator provided by
    OpenSSL; it is not affected by R’s RNG settings, and there’s no way
    to make it reproducible.)

2.  You scramble your secrets with
    [`secret_encrypt()`](https://httr2.r-lib.org/dev/reference/secrets.md)
    and store the resulting text directly in the source code of your
    package:

    ``` r
    secret_scrambled <- secret_encrypt("secret I need to work with an API", key)
    secret_scrambled
    #> [1] "2ISQ4r5vRq3A2WE7Mks4E_vSuXtteshSKJKqoa_uXKyy4zdgZKsPxsS57dR2tQw_8A"
    ```

3.  When needed, you descramble the secret using
    [`secret_decrypt()`](https://httr2.r-lib.org/dev/reference/secrets.md):

    ``` r
    secret_decrypt(secret_scrambled, key)
    #> [1] "secret I need to work with an API"
    ```

### Package keys and secrets

You can create any number of encryption keys, but I highly recommend
that you create one key per package, which I’ll call the **package**
key. In this section, I’ll show you how to store that key so that you
(and your automated tests) can use it, but no one else can.

httr2 is built around the notion that this key should live in an
environment variable. So the first step is to make your package key
available on your local development machine by adding a line to your
your user-level `.Renviron` (which you can easily open with
`usethis::edit_r_environ()`):

    YOURPACKAGE_KEY=key_you_generated_with_secret_make_key

Now (after you restart R), you’ll be able to take advantage of a special
[`secret_encrypt()`](https://httr2.r-lib.org/dev/reference/secrets.md)
and
[`secret_decrypt()`](https://httr2.r-lib.org/dev/reference/secrets.md)
feature: the `key` argument can be the name of an environment variable,
instead of the encryption key itself. In fact, this is most natural
usage.

``` r
secret_scrambled <- secret_encrypt("secret I need to work with an API", "YOURPACKAGE_KEY")
secret_scrambled
#> [1] "DW4OEZSKFRSAzu6sIlkBsF8jt5N13FKMl1nS-IFleLw1r4nHlK_1gvnytYwhEuRSvg"
secret_decrypt(secret_scrambled, "YOURPACKAGE_KEY")
#> [1] "secret I need to work with an API"
```

You’ll also need to make the key available in your GitHub Actions (both
check and pkgdown) so your automated tests can use it. This requires two
steps:

1.  Add the key to your [repository
    secrets](https://docs.github.com/en/actions/reference/encrypted-secrets).

2.  Share the key with the workflows that need it by adding a line to
    the appropriate workflow:

    ``` yaml
        env:
          YOURPACKAGE_KEY: ${{ secrets.YOURPACKAGE_KEY }}
    ```

    You can see how httr2 does it in [its GitHub
    workflow](https://github.com/r-lib/httr2/blob/master/.github/workflows/R-CMD-check.yaml).

Other continuous integration platforms will offer similar ways to make a
key available as a secure environment variable.

### When the package key isn’t available

There are a few important cases where your code won’t have access to
your package key: on CRAN, on the personal machines of external
contributors, and in automated checks on their PRs. So if you want to
share your package on CRAN or make it easy for others to contribute, you
need to make sure that your examples, vignettes, and tests all work
without error:

- In vignettes, you can run
  `knitr::opts_chunk(eval = secret_has_key("YOURPACKAGE_KEY"))` so that
  chunks are only evaluated if your key is available.

- In examples, you can surround code blocks that require your key with
  `if (httr2::secret_has_key("YOURPACKAGE_KEY")) {}`

- You don’t need to do anything in tests because when
  [`secret_decrypt()`](https://httr2.r-lib.org/dev/reference/secrets.md)
  is run by testthat, it will automatically `skip()` the test if the key
  isn’t available.

## NYTimes Books API

Next we’ll take a look at the NYTimes [Books
API](https://developer.nytimes.com/docs/books-product/1/overview). It
requires a very simple authentication with an API key that’s included in
every request. When you’re wrapping an API that has a key you’re going
to face two struggles:

- How do you test your package without sharing your key with the whole
  world?

- How do you allow your users to supply their own key, without having to
  pass it to every function?

So now you can understand how the following code works to get my NYTimes
Book API key:

``` r
my_key <- secret_decrypt("4Nx84VPa83dMt3X6bv0fNBlLbv3U4D1kHM76YisKEfpCarBm1UHJHARwJHCFXQSV", "HTTR2_KEY")
```

I’ll start by tackling the first problem because otherwise there’s no
way for me to show how the API works in this vignette 😃. We’ll come
back to the second at the very end of this section, because it’s easiest
to tackle once we have a function in place.

### Security considerations

Note that including an API key as a query parameter is relatively
insecure; if an API uses this method of auth, it’s typically because the
key is relatively easy to create or gives relatively few privileges.
Here it only takes a couple of minutes to generate your own NYTimes API
key, so there’s little incentive for someone to try and steal yours.

The main problem of conveying credentials via the url is that it’s
easily exposed, because httr2 makes no efforts to redact confidential
information stored in query parameters. This means it’s relatively easy
to leak your key if you use `req_perform(verbosity = 1)`,
[`req_dry_run()`](https://httr2.r-lib.org/dev/reference/req_dry_run.md),
or even just print the request object. And indeed, you’ll see that in
the examples below — this is bad practice for a real package, but I
think it’s ok here because the key doesn’t allow you to do anything
valuable and it makes teaching APIs so much easier.

### Basic request

Now let’s perform a test request and look at the response:

``` r
resp <- request("https://api.nytimes.com/svc/books/v3") |>
  req_url_path_append("/reviews.json") |>
  req_url_query(`api-key` = my_key, isbn = 9780307476463) |>
  req_perform()
resp
```

Like most modern APIs, this one returns the results as JSON:

``` r
resp |>
  resp_body_json() |>
  str()
```

Before we start wrapping this up into a function, let’s consider what
happens with errors.

### Error handling

What happens if there’s an error? For example, if we deliberately supply
an invalid key:

``` r
resp <- request("https://api.nytimes.com/svc/books/v3") |>
  req_url_path_append("/reviews.json") |>
  req_url_query(`api-key` = "invalid", isbn = 9780307476463) |>
  req_perform()
```

To see if there’s any extra useful information we can again look at
`last_response():`

``` r
resp <- last_response()
resp
resp |> resp_body_json()
```

It looks like there’s some useful additional info in the `faultstring`:

``` r
resp |> resp_body_json() |> _$fault |> _$faultstring
```

To add that information to future errors we can use the `body` argument
to [`req_error()`](https://httr2.r-lib.org/dev/reference/req_error.md).
This should be a function that takes a response and returns a character
vector of additional information to include in the error. Once we do
that and re-fetch the request, we see the additional information
displayed in the R error:

``` r
nytimes_error_body <- function(resp) {
  resp |> resp_body_json() |> _$fault |> _$faultstring
}

resp <- request("https://api.nytimes.com/svc/books/v3") |>
  req_url_path_append("/reviews.json") |>
  req_url_query(`api-key` = "invalid", isbn = 9780307476463) |>
  req_error(body = nytimes_error_body) |>
  req_perform()
```

### Rate limits

Another common source of errors is rate-limiting — this is used by many
servers to prevent one unruly client consuming too many resources. The
[frequently asked questions](https://developer.nytimes.com/faq#a11) page
describes the rate limits for the NYT APIs:

> Yes, there are two rate limits per API: 4,000 requests per day and 10
> requests per minute. You should sleep 6 seconds between calls to avoid
> hitting the per minute rate limit. If you need a higher rate limit,
> please contact us at <code@nytimes.com>.

Many APIs return additional information about how long to wait when the
rate limit is exceeded (often using the `Retry-After` header). So I
deliberately violated the rate limit by quickly making 11 requests;
unfortunately while the response was a standard 429 (Too many requests),
it did not include any information about how long to wait in either the
response body or the headers. That means we can’t use
[`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md),
which automatically waits the amount of time the server requests.
Instead, we’ll use
[`req_throttle()`](https://httr2.r-lib.org/dev/reference/req_throttle.md)
to ensure we don’t make more than 10 requests every 60 seconds:

``` r
req <- request("https://api.nytimes.com/svc/books/v3") |>
  req_url_path_append("/reviews.json") |>
  req_url_query(`api-key` = "invalid", isbn = 9780307476463) |>
  req_throttle(10 / 60)
```

By default,
[`req_throttle()`](https://httr2.r-lib.org/dev/reference/req_throttle.md)
shares the limit across all requests made to the host
(i.e. `api.nytimes.com`). Since the docs suggest the rate limit applies
per API, you might want to use the `realm` argument to be a bit more
specific:

``` r
req <- request("https://api.nytimes.com/svc/books/v3") |>
  req_url_path_append("/reviews.json") |>
  req_url_query(`api-key` = "invalid", isbn = 9780307476463) |>
  req_throttle(10 / 60, realm = "https://api.nytimes.com/svc/books")
```

### Wrapping it up

Putting together all the pieces above yields a function something like
this:

``` r
nytimes_books <- function(api_key, path, ...) {
  request("https://api.nytimes.com/svc/books/v3") |>
    req_url_path_append(path) |>
    req_url_query(..., `api-key` = api_key) |>
    req_error(body = nytimes_error_body) |>
    req_throttle(10 / 60, realm = "https://api.nytimes.com/svc/books") |>
    req_perform() |>
    resp_body_json()
}

drunk <- nytimes_books(my_key, "/reviews.json", isbn = "0316453382")
drunk$results[[1]]$summary
```

To finish this up for a real package, you’d want to:

- Add explicit arguments and check that they have the correct type.

- Export and document the function.

- Convert the nested list into a more user-friendly data structure
  (probably a data frame with one row per review).

You’d also want to provide some convenient way for the user to supply
their own API key.

### User-supplied key

A good place to start is an environment variable, because environment
variables are easy to set without typing anything in the console (which
can get accidentally shared via your `.Rhistory`) and are easily set in
automated processes. Then you’d write a function to retrieve the API
key, returning a helpful message if it’s not found:

``` r
get_api_key <- function() {
  key <- Sys.getenv("NYTIMES_KEY")
  if (identical(key, "")) {
    stop("No API key found, please supply with `api_key` argument or with NYTIMES_KEY env var")
  }
  key
}
```

Then you could modify `nytimes_books()` to use `get_api_key()` as the
default value for `api_key`. Since the argument is now optional, we can
move it to end of the argument list, since it’ll only be needed in
exceptional circumstances.

``` r
nytimes_books <- function(path, ..., api_key = get_api_key()) {
  ...
}
```

You can make this approach a little more user friendly by providing a
helper that sets the environment variable:

``` r
set_api_key <- function(key = NULL) {
  if (is.null(key)) {
    key <- askpass::askpass("Please enter your API key")
  }
  Sys.setenv("NYTIMES_KEY" = key)
}
```

Using askpass (or similar) here is good practice since you don’t want to
encourage the user to type their secret key into the console, as
mentioned above.

It’s a good idea to extend `get_api_key()` to automatically use your
encrypted key to make it easier to write tests:

``` r
get_api_key <- function() {
  key <- Sys.getenv("NYTIMES_KEY")
  if (!identical(key, "")) {
    return(key)
  }

  if (is_testing()) {
    return(testing_key())
  } else {
    stop("No API key found, please supply with `api_key` argument or with NYTIMES_KEY env var")
  }
}

is_testing <- function() {
  identical(Sys.getenv("TESTTHAT"), "true")
}

testing_key <- function() {
  secret_decrypt("4Nx84VPa83dMt3X6bv0fNBlLbv3U4D1kHM76YisKEfpCarBm1UHJHARwJHCFXQSV", "HTTR2_KEY")
}
```

## Github Gists API

Next we’ll take a look at an API that can make changes on behalf of a
user, not just retrieve data: [GitHub’s gist
API](https://docs.github.com/en/rest/reference/gists). This uses
different HTTP methods to perform different actions, like creating,
updating, and deleting gists. But before we can get to those, let’s
handle authentication, rate-limiting, and errors.

### Authentication

The easiest way to authenticate with a GitHub API is to use a personal
access token. A token is an alternative to a username and password. You
have one username + password per site; you can have one token per use
case. This lets each use case have a minimal set of permissions, and you
can easily revoke one token without affecting any other use case.

I created a personal access token specifically for this vignette that
can only access gists, and, as in the last example, stored an encrypted
version in this vignette:

``` r
token <- secret_decrypt("Guz59woxKoIO_JVtp2IzU3mFIU3ULtaUEa8xvvpYUBdVthR8jhxzc3bMZFhA9HL-ZK6YZudOI6g", "HTTR2_KEY")
```

If you want to run this vignette yourself, you’ll need to create a new
token in your [GitHub settings](https://github.com/settings/tokens);
just make sure it includes the “gist” scope. It’s also a good idea to
give every token a descriptive name, that reminds you of its motivating
use case, and of where to update it when you have to re-generate it
because it expired.

To authenticate a request with the token, we need to put it in the
`Authorization` header with a [“token”
prefix](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#authentication):

``` r
req <- request("https://api.github.com/gists") |>
  req_headers(Authorization = paste("token", token))

req |> req_perform()
```

Because the authorization header usually contains secret information,
httr2 automatically redacts it[¹](#fn1):

``` r
req
req |> req_dry_run()
```

### Errors

Once you’ve got authentication working, it’s always a good idea to work
on errors next, since that will help you debug any failed requests. In
my experience APIs rarely do a good job of documenting their errors, so
you’ll often have to do a little experimentation. To add to the pain, in
large APIs different endpoints often return different amounts of
information in different forms. You’ll typically need to tackle your
error handling iteratively, improving your code each time you encounter
a new problem.

While GitHub does [document its
errors](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#client-errors),
I’m sufficiently distrustful that I still want to construct a
deliberately malformed query and see what happens:

``` r
resp <- request("https://api.github.com/gists") |>
  req_url_query(since = "abcdef") |>
  req_headers(Authorization = paste("token", token)) |>
  req_perform()
```

As documented I get a 422 “Unprocessable Entity” error. But the response
is rather different to documentation which suggests there should be a
string `message` and a list of `errors`:

``` r
resp <- last_response()
resp
resp |> resp_body_json()
```

I’ll proceed anyway, writing a function that extracts the data and
formats it for presentation to the user:

``` r
gist_error_body <- function(resp) {
  body <- resp_body_json(resp)

  message <- body$message
  if (!is.null(body$documentation_url)) {
    message <- c(message, paste0("See docs at <", body$documentation_url, ">"))
  }
  message
}
gist_error_body(resp)
```

Now I can pass this function to the `body` argument of
[`req_error()`](https://httr2.r-lib.org/dev/reference/req_error.md) and
it will be automatically included in the error when a request fails:

``` r
request("https://api.github.com/gists") |>
  req_url_query(since = "yesterday") |>
  req_headers(Authorization = paste("token", token)) |>
  req_error(body = gist_error_body) |>
  req_perform()
```

Notice that each element of the character vector produced by
`gh_error_body()` becomes a bullet in the resulting error.

### Rate-limiting

While we’re thinking about errors, it’s useful to look at what happens
if the requests are rate limited. Luckily, GitHub consistently uses
response headers to provide information about the remaining [rate
limits](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting).

``` r
resp <- req |> req_perform()
resp |> resp_headers("ratelimit")
```

We can teach httr2 about this so it can automatically wait for a reset
if the rate limit is hit. We need to define two functions. The first
tells us whether or not a response has a transient error, i.e. it’s
worth waiting and trying again. For GitHub, when the rate limit is
[exceeded](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting),
the response has a 403 status and a `X-RateLimit-Remaining: 0` header:

``` r
gist_is_transient <- function(resp) {
  resp_status(resp) == 403 &&
    resp_header(resp, "X-RateLimit-Remaining") == "0"
}
gist_is_transient(resp)
```

Then we need a function tells how long to wait. GitHub tells us when the
rate limit resets (as number of seconds since 1970-01-01) in the
`X-RateLimit-Reset` header. To convert that to a number of seconds to
wait we first convert it to a number (since HTTP headers are always
strings), then subtract off the current time (in number of seconds since
1970-01-01):

``` r
gist_after <- function(resp) {
  time <- as.numeric(resp_header(resp, "X-RateLimit-Reset"))
  time - unclass(Sys.time())
}
gist_after(resp)
```

We then pass functions to
[`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md) so
httr2 has all the information it needs to handle rate-limiting
automatically:

``` r
request("http://api.github.com") |>
  req_retry(
    is_transient = gist_is_transient,
    after = gist_after,
    max_seconds = 60
  )
```

You also need to supply either `max_tries` or `max_seconds` in order to
activate
[`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md).

### Wrapping it all up

Let’s wrap up everything we’ve learned so far into a single function
that creates a request:

``` r
req_gist <- function(token) {
  request("https://api.github.com/gists") |>
    req_headers(Authorization = paste("token", token)) |>
    req_error(body = gist_error_body) |>
    req_retry(
      is_transient = gist_is_transient,
      after = gist_after
    )
}

# Check it works:
req_gist(token) |>
  req_perform()
```

We’ll use this as the basis to solve the next challenge: uploading a
gist.

### Sending data

To [create a
gist](https://docs.github.com/en/rest/reference/gists#create-a-gist) we
need to change the method to `POST` and add a body that contains data
encoded as JSON. httr2 provides one function that does both of these
things:
[`req_body_json()`](https://httr2.r-lib.org/dev/reference/req_body.md):

``` r
req <- req_gist(token) |>
  req_body_json(list(
    description = "This is my cool gist!",
    files = list(test.R = list(content = "print('Hi!')")),
    public = FALSE
  ))
req |> req_dry_run()
```

Depending on the API you’re wrapping, you might need to send data in a
different way.
[`req_body_form()`](https://httr2.r-lib.org/dev/reference/req_body.md)
and
[`req_body_multipart()`](https://httr2.r-lib.org/dev/reference/req_body.md)
make it easier to encode data in two other common forms. If the API
requires something different you can use
[`req_body_raw()`](https://httr2.r-lib.org/dev/reference/req_body.md).

Typically, the API will return some useful data about the resource
you’ve just created. Here I’ll extract the gist ID so we can use it in
the next examples, culminating with deleting the gist so I don’t end up
with a bunch of duplicated gists 😃.

``` r
resp <- req |> req_perform()
id <- resp |> resp_body_json() |> _$id
id
```

### Changing a gist

Actually, that description wasn’t very true and I want to change it. To
do so, I need to again send JSON encoded data, but this time I need to
use the `PATCH` verb. So after adding the data to request, I use
[`req_method()`](https://httr2.r-lib.org/dev/reference/req_method.md) to
override the default method:

``` r
req <- req_gist(token) |>
  req_url_path_append(id) |>
  req_body_json(list(description = "This is a simple gist")) |>
  req_method("PATCH")
req |> req_dry_run()
```

### Deleting a gist

Deleting a gist is similar, except we don’t send any data, we just need
to adjust the default method from `GET` to `DELETE`.

``` r
req <- req_gist(token) |>
  req_url_path_append(id) |>
  req_method("DELETE")
req |> req_dry_run()
req |> req_perform()
```

------------------------------------------------------------------------

1.  Again, it’s still possible to extract it with a little extra work,
    but httr2 tries to help you avoid revealing it by accident. httr2
    protects you from yourself, not from someone deliberately trying to
    find the secret.
