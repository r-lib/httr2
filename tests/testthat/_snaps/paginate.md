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
      ! `next_request` must have the arguments `req` and `parsed`; it currently has `req`.
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
      ! `n_pages` must have the argument `parsed`; it currently has `x`.

# multi_next_request() produces the request to the next page

    Code
      multi_next_request("a", req)
    Condition
      Error in `multi_next_request()`:
      ! `req` must be an HTTP request object, not the string "a".

# req_paginate_token() checks inputs

    Code
      req_paginate_token(req, "a")
    Condition
      Error in `req_paginate_token()`:
      ! `set_token` must be a function, not the string "a".
    Code
      req_paginate_token(req, function(req) resp)
    Condition
      Error in `req_paginate_token()`:
      ! `set_token` must have the arguments `req` and `next_token`; it currently has `req`.
    Code
      req_paginate_token(req, function(req, next_token) req, "a")
    Condition
      Error in `req_paginate_token()`:
      ! `parse_resp` must be a function, not the string "a".
    Code
      req_paginate_token(req, function(req, next_token) req, function(req) req)
    Condition
      Error in `req_paginate_token()`:
      ! `parse_resp` must have the argument `resp`; it currently has `req`.

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

# req_paginate_page_index() checks inputs

    Code
      req_paginate_page_index(req, "a")
    Condition
      Error in `req_paginate_page_index()`:
      ! `page_index` must be a function, not the string "a".
    Code
      req_paginate_page_index(req, function(req) req)
    Condition
      Error in `req_paginate_page_index()`:
      ! `page_index` must have the arguments `req` and `page`; it currently has `req`.

# parse_resp() produces a good error message

    Code
      req_not_a_list$policies$parse_resp(resp)
    Condition
      Error in `req_not_a_list$policies$parse_resp()`:
      ! `parse_resp(resp)` must be a list, not the string "a".
    Code
      req_missing_1_field$policies$parse_resp(resp)
    Condition
      Error in `req_missing_1_field$policies$parse_resp()`:
      ! The list returned by `parse_resp(resp)` is missing the field next_url.
    Code
      req_missing_2_field$policies$parse_resp(resp)
    Condition
      Error in `req_missing_2_field$policies$parse_resp()`:
      ! The list returned by `parse_resp(resp)` is missing the fields next_url and data.

---

    Code
      req_perform_multi(req, max_requests = 2, cancel_on_error = TRUE)
    Condition
      Error in `req_perform_multi()`:
      ! When parsing response 1.
      Caused by error in `parse_resp()`:
      ! The list returned by `parse_resp(resp)` is missing the field next_token.

