# Secret management

httr2 provides a handful of functions designed for working with
confidential data. These are useful because testing packages that use
httr2 often requires some confidential data that needs to be available
for testing, but should not be available to package users.

- `secret_encrypt()` and `secret_decrypt()` work with individual strings

- `secret_encrypt_file()` encrypts a file in place and
  `secret_decrypt_file()` decrypts a file in a temporary location.

- `secret_write_rds()` and `secret_read_rds()` work with `.rds` files

- `secret_make_key()` generates a random string to use as a key.

- `secret_has_key()` returns `TRUE` if the key is available; you can use
  it in examples and vignettes that you want to evaluate on your CI, but
  not for CRAN/package users.

These all look for the key in an environment variable. When used inside
of testthat, they will automatically
[`testthat::skip()`](https://testthat.r-lib.org/reference/skip.html) the
test if the env var isn't found. (Outside of testthat, they'll error if
the env var isn't found.)

## Usage

``` r
secret_make_key()

secret_encrypt(x, key)

secret_decrypt(encrypted, key)

secret_write_rds(x, path, key)

secret_read_rds(path, key)

secret_decrypt_file(path, key, envir = parent.frame())

secret_encrypt_file(path, key)

secret_has_key(key)
```

## Arguments

- x:

  Object to encrypt. Must be a string for `secret_encrypt()`.

- key:

  Encryption key; this is the password that allows you to "lock" and
  "unlock" the secret. The easiest way to specify this is as the name of
  an environment variable. Alternatively, if you already have a
  base64url encoded string, you can wrap it in
  [`I()`](https://rdrr.io/r/base/AsIs.html), or you can pass the raw
  vector in directly.

- encrypted:

  String to decrypt

- path:

  Path to file to encrypted file to read or write. For
  `secret_write_rds()` and `secret_read_rds()` this should be an `.rds`
  file.

- envir:

  The decrypted file will be automatically deleted when this environment
  exits. You should only need to set this argument if you want to pass
  the unencrypted file to another function.

## Value

- `secret_decrypt()` and `secret_encrypt()` return strings.

- `secret_decrypt_file()` returns a path to a temporary file;
  `secret_encrypt_file()` encrypts the file in place.

- `secret_write_rds()` returns `x` invisibly; `secret_read_rds()`
  returns the saved object.

- `secret_make_key()` returns a string with class `AsIs`.

- `secret_has_key()` returns `TRUE` or `FALSE`.

## Basic workflow

1.  Use `secret_make_key()` to generate a password. Make this available
    as an env var (e.g. `{MYPACKAGE}_KEY`) by adding a line to your
    `.Renviron`.

2.  Encrypt strings with `secret_encrypt()`, files with
    `secret_encrypt_file()`, and other data with `secret_write_rds()`,
    setting `key = "{MYPACKAGE}_KEY"`.

3.  In your tests, decrypt the data with `secret_decrypt()`,
    `secret_decrypt_file()`, or `secret_read_rds()` to match how you
    encrypt it.

4.  If you push this code to your CI server, it will already "work"
    because all functions automatically skip tests when your
    `{MYPACKAGE}_KEY` env var isn't set. To make the tests actually run,
    you'll need to set the env var using whatever tool your CI system
    provides for setting env vars. Make sure to carefully inspect the
    test output to check that the skips have actually gone away.

## Examples

``` r
key <- secret_make_key()

path <- tempfile()
secret_write_rds(mtcars, path, key = key)
secret_read_rds(path, key)
#>                      mpg cyl  disp  hp drat    wt  qsec vs am gear
#> Mazda RX4           21.0   6 160.0 110 3.90 2.620 16.46  0  1    4
#> Mazda RX4 Wag       21.0   6 160.0 110 3.90 2.875 17.02  0  1    4
#> Datsun 710          22.8   4 108.0  93 3.85 2.320 18.61  1  1    4
#> Hornet 4 Drive      21.4   6 258.0 110 3.08 3.215 19.44  1  0    3
#> Hornet Sportabout   18.7   8 360.0 175 3.15 3.440 17.02  0  0    3
#> Valiant             18.1   6 225.0 105 2.76 3.460 20.22  1  0    3
#> Duster 360          14.3   8 360.0 245 3.21 3.570 15.84  0  0    3
#> Merc 240D           24.4   4 146.7  62 3.69 3.190 20.00  1  0    4
#> Merc 230            22.8   4 140.8  95 3.92 3.150 22.90  1  0    4
#> Merc 280            19.2   6 167.6 123 3.92 3.440 18.30  1  0    4
#> Merc 280C           17.8   6 167.6 123 3.92 3.440 18.90  1  0    4
#> Merc 450SE          16.4   8 275.8 180 3.07 4.070 17.40  0  0    3
#> Merc 450SL          17.3   8 275.8 180 3.07 3.730 17.60  0  0    3
#> Merc 450SLC         15.2   8 275.8 180 3.07 3.780 18.00  0  0    3
#> Cadillac Fleetwood  10.4   8 472.0 205 2.93 5.250 17.98  0  0    3
#> Lincoln Continental 10.4   8 460.0 215 3.00 5.424 17.82  0  0    3
#> Chrysler Imperial   14.7   8 440.0 230 3.23 5.345 17.42  0  0    3
#> Fiat 128            32.4   4  78.7  66 4.08 2.200 19.47  1  1    4
#> Honda Civic         30.4   4  75.7  52 4.93 1.615 18.52  1  1    4
#> Toyota Corolla      33.9   4  71.1  65 4.22 1.835 19.90  1  1    4
#> Toyota Corona       21.5   4 120.1  97 3.70 2.465 20.01  1  0    3
#> Dodge Challenger    15.5   8 318.0 150 2.76 3.520 16.87  0  0    3
#> AMC Javelin         15.2   8 304.0 150 3.15 3.435 17.30  0  0    3
#> Camaro Z28          13.3   8 350.0 245 3.73 3.840 15.41  0  0    3
#> Pontiac Firebird    19.2   8 400.0 175 3.08 3.845 17.05  0  0    3
#> Fiat X1-9           27.3   4  79.0  66 4.08 1.935 18.90  1  1    4
#> Porsche 914-2       26.0   4 120.3  91 4.43 2.140 16.70  0  1    5
#> Lotus Europa        30.4   4  95.1 113 3.77 1.513 16.90  1  1    5
#> Ford Pantera L      15.8   8 351.0 264 4.22 3.170 14.50  0  1    5
#> Ferrari Dino        19.7   6 145.0 175 3.62 2.770 15.50  0  1    5
#> Maserati Bora       15.0   8 301.0 335 3.54 3.570 14.60  0  1    5
#> Volvo 142E          21.4   4 121.0 109 4.11 2.780 18.60  1  1    4
#>                     carb
#> Mazda RX4              4
#> Mazda RX4 Wag          4
#> Datsun 710             1
#> Hornet 4 Drive         1
#> Hornet Sportabout      2
#> Valiant                1
#> Duster 360             4
#> Merc 240D              2
#> Merc 230               2
#> Merc 280               4
#> Merc 280C              4
#> Merc 450SE             3
#> Merc 450SL             3
#> Merc 450SLC            3
#> Cadillac Fleetwood     4
#> Lincoln Continental    4
#> Chrysler Imperial      4
#> Fiat 128               1
#> Honda Civic            2
#> Toyota Corolla         1
#> Toyota Corona          1
#> Dodge Challenger       2
#> AMC Javelin            2
#> Camaro Z28             4
#> Pontiac Firebird       2
#> Fiat X1-9              1
#> Porsche 914-2          2
#> Lotus Europa           2
#> Ford Pantera L         4
#> Ferrari Dino           6
#> Maserati Bora          8
#> Volvo 142E             2

# While you can manage the key explicitly in a variable, it's much
# easier to store in an environment variable. In real life, you should
# NEVER use `Sys.setenv()` to create this env var because you will
# also store the secret in your `.Rhistory`. Instead add it to your
# .Renviron using `usethis::edit_r_environ()` or similar.
Sys.setenv("MY_KEY" = key)

x <- secret_encrypt("This is a secret", "MY_KEY")
x
#> [1] "dHCG7hWBhMgoY1ADGDEEkwGlxNAR35OuuB89vJ4eaJM"
secret_decrypt(x, "MY_KEY")
#> [1] "This is a secret"
```
