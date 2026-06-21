# validates issuer against the returned document

    Code
      oauth_server_metadata("https://example.com")
    Condition
      Error in `oauth_server_metadata()`:
      ! Metadata issuer doesn't match the requested `issuer`.
      * Requested "https://example.com".
      * Received "https://evil.com".

# requires either issuer or url

    Code
      oauth_server_metadata()
    Condition
      Error in `oauth_server_metadata()`:
      ! Must supply either `issuer` or `url`.

# has a useful print method

    Code
      meta
    Output
      <httr2_oauth_server_metadata>
      * issuer                : "https://example.com"
      * authorization_endpoint: "https://example.com/authorize"
      * token_endpoint        : "https://example.com/token"
      * and 3 more fields.

