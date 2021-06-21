# can unobfuscate obfuscated string

    Code
      obfuscate("test")
    Output
      obfuscated("ZlWk7g")
    Code
      obfuscated("ZlWk7g")
    Output
      <OBFUSCATED>

# can coerce to a key

    Code
      as_key("ENVVAR_THAT_DOESNT_EXIST")
    Error <rlang_error>
      Can't find envvar ENVVAR_THAT_DOESNT_EXIST
    Code
      as_key(1)
    Error <rlang_error>
      `key` must be a raw vector containing the key, a string giving the name of an env var, or a string wrapped in I() that contains the base64url encoded key

