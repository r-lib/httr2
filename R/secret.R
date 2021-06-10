#' Secret management
#'
#' @description
#' httr2 provides a handful of functions designed for working with confidential
#' data. These are useful because testing packages that use httr2 often
#' requires some confidential data that needs to be available for testing,
#' but should not be available to package users.
#'
#' * `secret_encrypt()` and `secret_decrypt()` work with individual strings
#' * `secret_read_rds()` and `secret_write_rds()` work with `.rds` files
#' * `secret_make_key()` generates a random string to use as a key.
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
#' 2.  Encrypt strings with `secret_encrypt()` and other data with
#'     `secret_write_rds()`, setting `key = "{MYPACKAGE}_KEY"`.
#'
#' 3.  In your tests, decrypt the data with `secret_decrypt()` or
#'     `secret_read_rds()` to match how you encrypt it.
#'
#' 4.  If you push this code to your CI server, it will already "work" because
#'     all functions automatically skip tests when your `{MYPACKAGE}_KEY}`
#'     env var isn't set. To make the tests actually run, you'll need to set
#'     the env var using whatever tool your CI system provides for setting
#'     env vars. Make sure to carefully inspect the test output to check that
#'     the skips have actually gone away.
#'
#' @name secrets
#' @aliases NULL
#' @examples
#' key <- secret_make_key()
#'
#' path <- tempfile()
#' secret_write_rds(mtcars, path, key = key)
#' secret_read_rds(path, key)
#'
#' # While you can manage the key explicitly in a variable, it's much
#' # easier to store in an env variable. In real life, you should NEVER
#' # use `Sys.setenv()` to create this env var (instead using .Renviron or
#' # similar) but I need to do it here since it's an example
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
  check_string(x, "`x`")
  key <- as_key(key)

  base64_url_encode(openssl::aes_ctr_encrypt(charToRaw(x), key, iv = httr_iv))
}
#' @export
#' @rdname secrets
#' @param encrypted String to decrypt
secret_decrypt <- function(encrypted, key) {
  check_string(encrypted, "`encrypted`")
  key <- as_key(key)

  rawToChar(openssl::aes_ctr_decrypt(base64_url_decode(encrypted), key, iv = httr_iv))
}

#' @export
#' @rdname secrets
#' @param path Path to `.rds` file
secret_read_rds <- function(path, key) {
  key <- as_key(key)

  x_enc <- readBin(path, "raw", file.size(path))
  x_cmp <- openssl::aes_ctr_decrypt(x_enc, key, iv = httr_iv)
  x <- memDecompress(x_cmp, "bzip2")
  unserialize(x)
}

#' @export
#' @rdname secrets
secret_write_rds <- function(x, path, key) {
  key <- as_key(key)

  x <- serialize(x, NULL)
  x_cmp <- memCompress(x, "bzip2")
  x_enc <- openssl::aes_ctr_encrypt(x_cmp, key, iv = httr_iv)
  attr(x_enc, "iv") <- NULL # writeBin uses is.vector()
  writeBin(x_enc, path)
}

secret_get_key <- function(envvar) {
  key <- Sys.getenv(envvar)

  if (identical(key, "")) {
    msg <- glue("Can't find envvar {envvar}")
    if (is_testing()) {
      testthat::skip(msg)
    } else {
      abort(msg)
    }
  }

  base64_url_decode(key)
}


#' Obfuscate mildly secret information
#'
#' @description
#' This pair of functions provides a way to obfuscate mildly confidential
#' information, like OAuth client secrets. The secret can not be revealed
#' from your source code, but a good R programmer could still figure it
#' out with a little effort. The main goal is to protect against scraping;
#' there's no way for an automated tool to grab your obfuscated secrets.
#'
#' Because un-obfuscation happens at the last possible instant, `obfuscated()`
#' only works in limited locations; currently only the `secret` argument to
#' [oauth_client()].
#'
#' @param x A string to obfuscate, or mark as obfuscated.
#' @return `obfuscate()` prints the `obfuscated()` call to include in your
#'   code. `obfuscated()` returns an S3 class marking the string as obfuscated
#'   so it can be unobfuscated when needed.
#' @export
#' @examples
#' obfuscate("good morning")
#' obfuscated("dV-4_vKoUp90pP_M")
obfuscate <- function(x) {
  check_string(x, "`x`")

  enc <- secret_encrypt(x, obfuscate_key)
  glue('obfuscated("{enc}")')
}
attr(obfuscate, "srcref") <- "function(x) {}"

#' @export
#' @rdname obfuscate
obfuscated <- function(x) {
  structure(x, class = "httr2_obfuscated")
}

#' @export
format.httr2_obfuscated <- function(x, ...) {
  "<OBFUSCATED>"
}

#' @export
print.httr2_obfuscated <- function(x, ...) {
  cat(format(x), "\n", sep = "")
  invisible(x)
}

unobfuscate <- function(x, arg_name) {
  if (is.null(x)) {
    x
  } else if (inherits(x, "httr2_obfuscated")) {
    secret_decrypt(x, obfuscate_key)
  } else if (is_string(x)) {
    x
  } else {
    abort(glue("{arg_name} must be a string"))
  }
}
attr(unobfuscate, "srcref") <- "function(x) {}"

obfuscate_key <- as.raw(c(
  0xf7, 0x76, 0x13, 0x88, 0x76, 0x01, 0x6f, 0xb7,
  0x67, 0xd5, 0xca, 0x45, 0x8b, 0xbb, 0x24, 0x2e
))


# Helpers -----------------------------------------------------------------

as_key <- function(x) {
  if (inherits(x, "AsIs") && is_string(x)) {
    base64_url_decode(x)
  } else if (is.raw(x)) {
    x
  } else if (is_string(x)) {
    secret_get_key(x)
  } else {
    abort("key` must be a raw vector or a base64 url encoded string")
  }
}

# Fixed iv is not good idea in general, but fine here since we're not
# worried about dictionary attacks
httr_iv <- as.raw(c(
  0x4d, 0x11, 0x18, 0x6f, 0x51, 0xf1, 0x5a, 0x36,
  0x12, 0x74, 0x9b, 0x54, 0x0e, 0x13, 0x33, 0x3c
))
