# obfuscated strings are hidden

    Code
      x <- obfuscated("abcdef")
      x
    Output
      <OBFUSCATED>
    Code
      str(x)
    Output
       <OBFUSCATED>

# can coerce to a key

    Code
      as_key("ENVVAR_THAT_DOESNT_EXIST")
    Condition
      Error in `secret_get_key()` at httr2/R/secret.R:233:4:
      ! Can't find envvar ENVVAR_THAT_DOESNT_EXIST
    Code
      as_key(1)
    Condition
      Error in `as_key()`:
      ! `key` must be a raw vector containing the key, a string giving the name of an env var, or a string wrapped in I() that contains the base64url encoded key

