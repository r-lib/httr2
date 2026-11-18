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
#' @seealso [Managing secrets](https://httr2.r-lib.org/articles/secrets.html)
#'   for a full overview of how httr2 helps you keep credentials safe.
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
#' @param encrypted String to decrypt.
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
  withr::defer(unlink(path, force = TRUE), envir)
  writeBin(dec, path)
  Sys.chmod(path, "400")
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
  base64_url_decode(envvar_get(envvar, call = call))
}

envvar_get <- function(name, call = caller_env()) {
  value <- Sys.getenv(name)
  if (identical(value, "")) {
    msg <- cli::format_inline("Can't find env var {.envvar {name}}.")
    if (is_testing()) {
      testthat::skip(msg)
    } else {
      cli::cli_abort(msg, class = "httr2_secret_missing", call = call)
    }
  }
  value
}


#' Obfuscate mildly secret information
#'
#' @description
#' Use `obfuscate("value")` to generate a call to `obfuscated()`, which will
#' unobfuscate the value at the last possible moment. Obfuscated values only
#' work in limited locations:
#'
#' * Header values in [req_headers()]
#' * The `password` argument to [req_auth_basic()] and the `token` argument
#'   to [req_auth_bearer_token()]
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
#' @seealso [Managing secrets](https://httr2.r-lib.org/articles/secrets.html)
#'   for other (generally better) ways to manage secrets.
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
str.httr2_obfuscated <- function(object, ..., nest.lev = 0) {
  str_leading_space(nest.lev)
  cat(glue('obfuscated("{object}")'), "\n", sep = "")
}

#' @export
print.httr2_obfuscated <- function(x, ...) {
  cat(glue('obfuscated("{x}")\n'))
  invisible(x)
}

is_obfuscated <- function(x) {
  inherits(x, "httr2_obfuscated")
}

# Deferred secrets ----------------------------------------------------------

#' Secrets resolved at perform time
#'
#' @description
#' These functions create *secrets*: recipes for obtaining a credential that
#' httr2 resolves only when the request is performed. Secrets are redacted
#' wherever httr2 displays them (e.g. in [print()], [req_dry_run()], and
#' [req_verbose()]), so they can't leak into console output or log files.
#'
#' * `secret_envvar()` records the name of an environment variable, reading
#'   its value at perform time. This is the recommended way to supply
#'   credentials: store the value in your `.Renviron` (for local work) or in
#'   your CI system's secret store, and never put it in your code.
#' * `secret_value()` wraps a value you already have. The value is held in a
#'   weak reference, so it is never written to disk: if you save a request
#'   (with e.g. [saveRDS()]) that contains a `secret_value()` and reload it,
#'   the secret is silently dropped from headers and errors when revealed
#'   from a body.
#'
#' Additionally, any zero-argument function that returns a string can be used
#' as a secret, e.g. `\() keyring::key_get("example")`. Note that a function
#' is saved with whatever it captures: `\() key` stores `key` inside the
#' request, so either look the value up inside the function or wrap it in
#' `secret_value()`.
#'
#' Secrets can be used in [req_headers()], [req_auth_basic()],
#' [req_auth_bearer_token()], [req_auth_aws_v4()], [oauth_client()], and in
#' the bodies of [req_body_json()], [req_body_form()], and
#' [req_body_multipart()].
#'
#' @param x A string to store.
#' @param name The name of an environment variable.
#' @returns A secret.
#' @seealso [Managing secrets](https://httr2.r-lib.org/articles/secrets.html)
#'   for a full overview of working with secrets.
#' @export
#' @examples
#' req <- request("http://example.com")
#'
#' # In real life, set the env var in your .Renviron, not with Sys.setenv()
#' Sys.setenv(EXAMPLE_TOKEN = "token123")
#'
#' # Read the token from an env var at perform time:
#' req |>
#'   req_auth_bearer_token(secret_envvar("EXAMPLE_TOKEN")) |>
#'   req_dry_run()
secret_value <- function(x) {
  check_string(x)
  new_secret_value(x)
}

# Like secret_value(), but without the input check, so that new_headers()
# can wrap any already-flattened value.
new_secret_value <- function(x) {
  env <- new_environment(parent = baseenv())
  env$ref <- new_weakref(env, x)
  f <- function() rlang::wref_value(get("ref", environment()))
  environment(f) <- env
  structure(f, class = c("httr2_secret_value", "function"))
}

is_secret_value <- function(x) {
  inherits(x, "httr2_secret_value")
}

is_secret_dropped <- function(x) {
  is_secret_value(x) && is.null(x())
}

#' @export
format.httr2_secret_value <- function(x, ...) {
  secret_format(x)
}
#' @export
print.httr2_secret_value <- function(x, ...) {
  cat(format(x), "\n", sep = "")
  invisible(x)
}
#' @export
str.httr2_secret_value <- function(object, ..., nest.lev = 0) {
  str_leading_space(nest.lev)
  cat(secret_format(object), "\n", sep = "")
}

#' @export
#' @rdname secret_value
secret_envvar <- function(name) {
  check_string(name, allow_empty = FALSE)
  structure(
    function() envvar_get(name),
    class = c("httr2_secret_envvar", "function")
  )
}

is_secret_envvar <- function(x) {
  inherits(x, "httr2_secret_envvar")
}

#' @export
format.httr2_secret_envvar <- function(x, ...) {
  secret_format(x)
}
#' @export
print.httr2_secret_envvar <- function(x, ...) {
  cat(format(x), "\n", sep = "")
  invisible(x)
}
#' @export
str.httr2_secret_envvar <- function(object, ..., nest.lev = 0) {
  str_leading_space(nest.lev)
  cat(secret_format(object), "\n", sep = "")
}

is_secret <- function(x) {
  is_obfuscated(x) || is.function(x)
}

# Derives a new secret from an existing secret (or a plain value) by applying
# `f` to its value. If `x` is not a secret, applies `f` and returns a plain
# value, so callers can use one code path for both secret and plain input.
secret_map <- function(x, f) {
  f <- as_function(f)
  if (!is_secret(x)) {
    f(x)
  } else if (is_secret_value(x)) {
    # Apply immediately so that `f` isn't stored with the secret
    new_secret_value(f(secret_reveal(x)))
  } else {
    attr(x, "httr2_secret_map") <- c(attr(x, "httr2_secret_map"), list(f))
    x
  }
}

# Recursively resolve every secret in `x`
secrets_resolve <- function(x, handle = c("reveal", "redact", "remove")) {
  handle <- arg_match(handle)
  secrets_resolve_rec(x, handle)
}
secrets_resolve_rec <- function(x, handle) {
  if (is_secret(x)) {
    switch(
      handle,
      reveal = secret_reveal(x),
      redact = secret_format(x),
      remove = NULL
    )
  } else if (is.list(x)) {
    x[] <- lapply(x, secrets_resolve_rec, handle = handle)
    x
  } else {
    x
  }
}

secret_reveal <- function(x) {
  value <- secret_reveal_base(x)
  for (f in attr(x, "httr2_secret_map")) {
    value <- f(value)
  }
  if (!is_string(value)) {
    cli::cli_abort(
      "A secret must resolve to a single string, not {obj_type_friendly(value)}."
    )
  }
  value
}

secret_reveal_base <- function(x) {
  if (is_obfuscated(x)) {
    # Strip attributes so `httr2_secret_map` doesn't confuse the decryption
    secret_decrypt(as.character(x), obfuscate_key())
  } else if (is_secret_dropped(x)) {
    cli::cli_abort(
      c(
        "A {.fn secret_value} is no longer available.",
        i = "Secret values are removed when a request is saved; re-create it."
      ),
      class = "httr2_secret_dropped"
    )
  } else if (is.function(x)) {
    x()
  } else {
    cli::cli_abort("Unknown secret type.", .internal = TRUE)
  }
}

secret_format <- function(x) {
  if (is_secret_value(x)) {
    "<REDACTED>"
  } else if (is_obfuscated(x)) {
    "<REDACTED (obfuscated)>"
  } else if (is_secret_envvar(x)) {
    paste0("<REDACTED (env: ", fn_env(x)$name, ")>")
  } else {
    "<REDACTED (on-demand)>"
  }
}

check_string_or_secret <- function(
  x,
  ...,
  allow_null = FALSE,
  arg = caller_arg(x),
  call = caller_env()
) {
  if (is_secret(x)) {
    return(invisible(x))
  }
  check_string(x, ..., allow_null = allow_null, arg = arg, call = call)
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
