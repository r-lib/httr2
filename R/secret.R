#' Secret management
#'
#' @description
#' httr2 provides a handful of functions designed for working with confidential
#' data. These are useful because testing packages that use httr2 often
#' requires some confidential data that needs to be available for testing,
#' but should not be available to package users.
#'
#' * `secret_encrypt()` and `secret_decrypt()` work with individual strings
#' * `secret_encrypt_file()` encrypts a file in place and
#'   `secret_decrypt_file()` decrypts a file in a temporary location.
#' * `secret_write_rds()` and `secret_read_rds()` work with `.rds` files
#' * `secret_make_key()` generates a random string to use as a key.
#' * `secret_has_key()` returns `TRUE` if the key is available; you can
#'   use it in examples and vignettes that you want to evaluate on your CI,
#'   but not for CRAN/package users.
#'
#' These all look for the key in an environment variable. When used inside of
#' testthat, they will automatically [testthat::skip()] the test if the env var
#' isn't found. (Outside of testthat, they'll error if the env var isn't
#' found.)
#'
#' # Basic workflow
#'
#' 1.  Use `secret_make_key()` to generate a password. Make this available
#'     as an env var (e.g. `{MYPACKAGE}_KEY`) by adding a line to your
#'     `.Renviron`.
#'
#' 2.  Encrypt strings with `secret_encrypt()`, files with
#'     `secret_encrypt_file()`, and other data with `secret_write_rds()`,
#'     setting `key = "{MYPACKAGE}_KEY"`.
#'
#' 3.  In your tests, decrypt the data with `secret_decrypt()`,
#'     `secret_decrypt_file()`, or `secret_read_rds()` to match how you encrypt
#'     it.
#'
#' 4.  If you push this code to your CI server, it will already "work" because
#'     all functions automatically skip tests when your `{MYPACKAGE}_KEY`
#'     env var isn't set. To make the tests actually run, you'll need to set
#'     the env var using whatever tool your CI system provides for setting
#'     env vars. Make sure to carefully inspect the test output to check that
#'     the skips have actually gone away.
#'
#' @name secrets
#' @returns
#' * `secret_decrypt()` and `secret_encrypt()` return strings.
#' * `secret_decrypt_file()` returns a path to a temporary file;
#'   `secret_encrypt_file()` encrypts the file in place.
#' * `secret_write_rds()` returns `x` invisibly; `secret_read_rds()`
#'   returns the saved object.
#' * `secret_make_key()` returns a string with class `AsIs`.
#' * `secret_has_key()` returns `TRUE` or `FALSE`.
#' @aliases NULL
#' @examples
#' key <- secret_make_key()
#'
#' path <- tempfile()
#' secret_write_rds(mtcars, path, key = key)
#' secret_read_rds(path, key)
#'
#' # While you can manage the key explicitly in a variable, it's much
#' # easier to store in an environment variable. In real life, you should
#' # NEVER use `Sys.setenv()` to create this env var because you will
#' # also store the secret in your `.Rhistory`. Instead add it to your
#' # .Renviron using `usethis::edit_r_environ()` or similar.
#' Sys.setenv("MY_KEY" = key)
#'
#' x <- secret_encrypt("This is a secret", "MY_KEY")
#' x
#' secret_decrypt(x, "MY_KEY")
NULL

#' @export
#' @rdname secrets
secret_make_key <- function() {
  I(base64_url_rand(16))
}

#' @export
#' @rdname secrets
#' @param x Object to encrypt. Must be a string for `secret_encrypt()`.
#' @param key Encryption key; this is the password that allows you to "lock"
#'   and "unlock" the secret. The easiest way to specify this is as the
#'   name of an environment variable. Alternatively, if you already have
#'   a base64url encoded string, you can wrap it in `I()`, or you can pass
#'   the raw vector in directly.
secret_encrypt <- function(x, key) {
  check_string(x)

  enc <- secret_encrypt_raw(charToRaw(x), key)
  base64_url_encode(enc)
}
#' @export
#' @rdname secrets
#' @param encrypted String to decrypt
secret_decrypt <- function(encrypted, key) {
  check_string(encrypted)

  enc <- base64_url_decode(encrypted)
  dec <- secret_decrypt_raw(enc, key)

  rawToChar(dec)
}

#' @export
#' @rdname secrets
secret_write_rds <- function(x, path, key) {
  x <- serialize(x, NULL, version = 2)
  x_cmp <- memCompress(x, "bzip2")
  enc <- secret_encrypt_raw(x_cmp, key)
  writeBin(enc, path)

  invisible(x)
}
#' @export
#' @rdname secrets
#' @param path Path to file to encrypted file to read or write. For
#'  `secret_write_rds()` and `secret_read_rds()` this should be an `.rds`
#'  file.
secret_read_rds <- function(path, key) {
  enc <- readBin(path, "raw", file.size(path))
  dec_cmp <- secret_decrypt_raw(enc, key)
  dec <- memDecompress(dec_cmp, "bzip2")

  unserialize(dec)
}

#' @export
#' @param envir The decrypted file will be automatically deleted when
#'   this environment exits. You should only need to set this argument if you
#'   want to pass the unencrypted file to another function.
#' @rdname secrets
secret_decrypt_file <- function(path, key, envir = parent.frame()) {
  enc <- readBin(path, "raw", file.size(path))
  dec <- secret_decrypt_raw(enc, key = key)

  path <- tempfile()
  withr::defer(unlink(path), envir)
  writeBin(dec, path)
  Sys.chmod(path, 400)
  path
}

#' @export
#' @rdname secrets
secret_encrypt_file <- function(path, key) {
  dec <- readBin(path, "raw", file.info(path)$size)
  enc <- secret_encrypt_raw(dec, key = key)

  writeBin(enc, path)
  invisible(path)
}

#' @export
#' @rdname secrets
secret_has_key <- function(key) {
  check_string(key)
  key <- Sys.getenv(key)
  !identical(key, "")
}

secret_get_key <- function(envvar, call = caller_env()) {
  key <- Sys.getenv(envvar)

  if (identical(key, "")) {
    msg <- glue("Can't find envvar {envvar}")
    if (is_testing()) {
      testthat::skip(msg)
    } else {
      abort(msg, call = call)
    }
  }

  base64_url_decode(key)
}


#' Obfuscate mildly secret information
#'
#' @description
#' Use `obfuscate("value")` to generate a call to `obfuscated()`, which will
#' unobfuscate the value at the last possible moment. Obfuscated values only
#' work in limited locations:
#'
#' * The `secret` argument to [oauth_client()]
#' * Elements of the `data` argument to [req_body_form()], `req_body_json()`,
#'   and `req_body_multipart()`.
#'
#' Working together this pair of functions provides a way to obfuscate mildly
#' confidential information, like OAuth client secrets. The secret can not be
#' revealed from your inspecting source code, but a skilled R programmer could
#' figure it out with some effort. The main goal is to protect against scraping;
#' there's no way for an automated tool to grab your obfuscated secrets.
#'
#' @param x A string to `obfuscate`, or mark as `obfuscated`.
#' @returns `obfuscate()` prints the `obfuscated()` call to include in your
#'   code. `obfuscated()` returns an S3 class marking the string as obfuscated
#'   so it can be unobfuscated when needed.
#' @export
#' @examples
#' obfuscate("good morning")
#'
#' # Every time you obfuscate you'll get a different value because it
#' # includes 16 bytes of random data which protects against certain types of
#' # brute force attack
#' obfuscate("good morning")
obfuscate <- function(x) {
  check_string(x)

  enc <- secret_encrypt(x, obfuscate_key())
  glue('obfuscated("{enc}")')
}
attr(obfuscate, "srcref") <- "function(x) {}"

#' @export
#' @rdname obfuscate
obfuscated <- function(x) {
  structure(x, class = "httr2_obfuscated")
}

#' @export
str.httr2_obfuscated <- function(object, ...) {
  cat(" ", glue('obfuscated("{object}")\n'), sep = "")
}

#' @export
print.httr2_obfuscated <- function(x, ...) {
  cat(glue('obfuscated("{x}")\n'))
  invisible(x)
}

unobfuscate <- function(x, handle = c("reveal", "redact", "remove")) {
  handle <- arg_match(handle)
  unobfuscate_rec(x, handle = handle)
}
unobfuscate_rec <- function(x, handle = "reveal") {
  if (is_obfuscated(x)) {
    switch(
      handle,
      reveal = secret_decrypt(x, obfuscate_key()),
      redact = "<REDACTED>",
      remove = NULL
    )
  } else if (is.list(x)) {
    x[] <- lapply(x, unobfuscate, handle = handle)
    x
  } else {
    x
  }
}
attr(unobfuscate, "srcref") <- "function(x) {}"

is_obfuscated <- function(x) {
  inherits(x, "httr2_obfuscated")
}

# Helpers -----------------------------------------------------------------

secret_encrypt_raw <- function(dec, key, error_call = caller_env()) {
  key <- as_key(key, error_call = error_call)

  enc <- openssl::aes_ctr_encrypt(dec, key)
  c(attr(enc, "iv"), enc)
}

secret_decrypt_raw <- function(enc, key, error_call = caller_env()) {
  key <- as_key(key, error_call = error_call)

  iv <- enc[1:16]
  value <- enc[-(1:16)]

  openssl::aes_ctr_decrypt(value, key, iv = iv)
}

as_key <- function(x, error_call = caller_env()) {
  if (inherits(x, "AsIs") && is_string(x)) {
    base64_url_decode(x)
  } else if (is.raw(x)) {
    x
  } else if (is_string(x)) {
    secret_get_key(x, call = error_call)
  } else {
    cli::cli_abort(
      paste0(
        "{.arg key} must be a raw vector containing the key, ",
        "a string giving the name of an env var, ",
        "or a string wrapped in {.fn I} that contains the base64url encoded key."
      ),
      call = error_call
    )
  }
}
