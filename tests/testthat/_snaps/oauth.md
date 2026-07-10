# req_oauth validates and stores expiry margin

    Code
      req_oauth(req, "", list(), NULL, expiry_margin = -1)
    Condition
      Error in `req_oauth()`:
      ! `expiry_margin` must be a whole number larger than or equal to 0, not the number -1.

# can store on disk

    Code
      cache$set(1)
    Message
      Caching httr2 token in '<oauth-cache-path>/httr2-test/2c0a8a99dc147d5445c3b49d035665b2-token.rds.enc'.

