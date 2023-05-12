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

# can coerce to a key

    Code
      as_key("ENVVAR_THAT_DOESNT_EXIST")
    Condition
      Error in `as_key()`:
      ! Can't find envvar ENVVAR_THAT_DOESNT_EXIST
    Code
      as_key(1)
    Condition
      Error in `as_key()`:
      ! `key` must be a raw vector containing the key, a string giving the name of an env var, or a string wrapped in I() that contains the base64url encoded key

