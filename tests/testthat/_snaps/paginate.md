# req_paginate() checks inputs

    Code
      req_paginate("a", next_request)
    Condition
      Error in `req_paginate()`:
      ! `req` must be an HTTP request object, not the string "a".
    Code
      req_paginate(req, "a")
    Condition
      Error in `req_paginate()`:
      ! `next_request` must be a function, not the string "a".
    Code
      req_paginate(req, function(req) req)
    Condition
      Error in `req_paginate()`:
      ! `next_request` must have the arguments `req`, `resp`, and `parsed`; it currently has `req`.
    Code
      req_paginate(req, next_request, parse_resp = "a")
    Condition
      Error in `req_paginate()`:
      ! `parse_resp` must be a function or `NULL`, not the string "a".
    Code
      req_paginate(req, next_request, parse_resp = function(x) x)
    Condition
      Error in `req_paginate()`:
      ! `parse_resp` must have the argument `resp`; it currently has `x`.
    Code
      req_paginate(req, next_request, n_pages = "a")
    Condition
      Error in `req_paginate()`:
      ! `n_pages` must be a function or `NULL`, not the string "a".
    Code
      req_paginate(req, next_request, n_pages = function(x) x)
    Condition
      Error in `req_paginate()`:
      ! `n_pages` must have the arguments `resp` and `parsed`; it currently has `x`.

# paginate_next_request() produces the request to the next page

    Code
      paginate_next_request("a", req)
    Condition
      Error in `paginate_next_request()`:
      ! `resp` must be an HTTP response object, not the string "a".
    Code
      paginate_next_request(resp, "a")
    Condition
      Error in `paginate_next_request()`:
      ! `req` must be an HTTP request object, not the string "a".
    Code
      paginate_next_request(resp, request("http://example.com/"))
    Condition
      Error in `check_has_pagination_policy()`:
      ! `req` doesn't have a pagination policy.
      i You can add pagination via `req_paginate()`.

# req_paginate_next_url() checks inputs

    Code
      req_paginate_next_url(request("http://example.com/"), "a")
    Condition
      Error in `req_paginate_next_url()`:
      ! `next_url` must be a function, not the string "a".
    Code
      req_paginate_next_url(request("http://example.com/"), function(req, parsed) req)
    Condition
      Error in `req_paginate_next_url()`:
      ! `next_url` must have the arguments `resp` and `parsed`; it currently has `req` and `parsed`.

# req_paginate_offset() checks inputs

    Code
      req_paginate_offset(req, "a")
    Condition
      Error in `req_paginate_offset()`:
      ! `offset` must be a function, not the string "a".
    Code
      req_paginate_offset(req, function(req) req)
    Condition
      Error in `req_paginate_offset()`:
      ! `offset` must have the arguments `req` and `offset`; it currently has `req`.
    Code
      req_paginate_offset(req, function(req, offset) req, page_size = "a")
    Condition
      Error in `req_paginate_offset()`:
      ! `page_size` must be a whole number, not the string "a".

# req_paginate_token() checks inputs

    Code
      req_paginate_token(req, "a")
    Condition
      Error in `req_paginate_token()`:
      ! `set_token` must be a function, not the string "a".
    Code
      req_paginate_token(req, function(req) req)
    Condition
      Error in `req_paginate_token()`:
      ! `set_token` must have the arguments `req` and `token`; it currently has `req`.
    Code
      req_paginate_token(req, function(req, token) req, next_token = "a")
    Condition
      Error in `req_paginate_token()`:
      ! `next_token` must be a function, not the string "a".
    Code
      req_paginate_token(req, function(req, token) req, next_token = function(req)
      req)
    Condition
      Error in `req_paginate_token()`:
      ! `next_token` must have the arguments `resp` and `parsed`; it currently has `req`.

# paginate_req_perform() checks inputs

    Code
      paginate_req_perform("a")
    Condition
      Error in `paginate_req_perform()`:
      ! `req` must be an HTTP request object, not the string "a".
    Code
      paginate_req_perform(request("http://example.com"))
    Condition
      Error in `check_has_pagination_policy()`:
      ! `req` doesn't have a pagination policy.
      i You can add pagination via `req_paginate()`.
    Code
      paginate_req_perform(req, max_pages = 0)
    Condition
      Error in `paginate_req_perform()`:
      ! `max_pages` must be a whole number larger than or equal to 1, not the number 0.
    Code
      paginate_req_perform(req, progress = "a")
    Condition
      Error in `paginate_req_perform()`:
      ! `progress` must be `TRUE` or `FALSE`, not the string "a".

