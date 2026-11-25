# obfuscated strings are hidden

    Code
      x <- obfuscated("abcdef")
      x
    Output
      obfuscated("abcdef")
    Code
      str(x)
    Output
      obfuscated("abcdef")

# secret_value reveals in memory and redacts on display

    Code
      x
    Output
      <REDACTED>
    Code
      str(x)
    Output
      <REDACTED>

# secret_value checks its input

    Code
      secret_value(1)
    Condition
      Error in `secret_value()`:
      ! `x` must be a single string, not the number 1.

# secret_value doesn't survive serialization

    Code
      secret_reveal(x2)
    Condition
      Error in `secret_reveal_base()`:
      ! A `secret_value()` is no longer available.
      i Secret values are removed when a request is saved; re-create it.

# secret_envvar errors if env var is missing

    Code
      secret_reveal(secret_envvar("DOESNT_EXIST"))
    Condition
      Error in `x()`:
      ! Can't find env var `DOESNT_EXIST`.

# secret_envvar shows the env var name on display

    Code
      x <- secret_envvar("NYTIMES_KEY")
      x
    Output
      <REDACTED (env: NYTIMES_KEY)>
    Code
      str(x)
    Output
      <REDACTED (env: NYTIMES_KEY)>

# secret_envvar checks its input

    Code
      secret_envvar(1)
    Condition
      Error in `secret_envvar()`:
      ! `name` must be a single string, not the number 1.
    Code
      secret_envvar("")
    Condition
      Error in `secret_envvar()`:
      ! `name` must be a single string, not the empty string "".

# secrets must resolve to a single string

    Code
      secret_reveal(function() 1)
    Condition
      Error in `secret_reveal()`:
      ! A secret must resolve to a single string, not the number 1.
    Code
      secret_reveal(function() letters)
    Condition
      Error in `secret_reveal()`:
      ! A secret must resolve to a single string, not a character vector.

# can coerce to a key

    Code
      as_key("ENVVAR_THAT_DOESNT_EXIST")
    Condition
      Error:
      ! Can't find env var `ENVVAR_THAT_DOESNT_EXIST`.
    Code
      as_key(1)
    Condition
      Error:
      ! `key` must be a raw vector containing the key, a string giving the name of an env var, or a string wrapped in `I()` that contains the base64url encoded key.

