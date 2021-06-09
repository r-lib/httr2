# can unobfuscate obfuscated string

    Code
      obfuscate("test")
    Output
      obfuscated("ZlWk7g")
    Code
      obfuscated("ZlWk7g")
    Output
      <OBFUSCATED>

# unobfuscate serves as argument checker

    Code
      unobfuscate(1, "`x`")
    Error <rlang_error>
      `x` must be a string

