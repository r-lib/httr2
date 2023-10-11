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

# paginate_next_request() produces the request to the next page

    Code
      paginate_next_request("a", req)
    Condition
      Error in `paginate_next_request()`:
      ! `req` must be an HTTP request object, not the string "a".
    Code
      paginate_next_request(req, "a")
    Message
      <httr2_request>
      GET http://example.com/2
      Body: empty
      Policies:
      * paginate: a list

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

# req_perform_iterate() checks inputs

    Code
      req_perform_iterate("a")
    Condition
      Error in `req_perform_iterate()`:
      ! `req` must be an HTTP request object, not the string "a".
    Code
      req_perform_iterate(request("http://example.com"))
    Condition
      Error in `check_has_pagination_policy()`:
      ! `req` doesn't have a pagination policy.
      i You can add pagination via `req_paginate()`.
    Code
      req_perform_iterate(req, max_pages = 0)
    Condition
      Error in `req_perform_iterate()`:
      ! `max_pages` must be a whole number larger than or equal to 1, not the number 0.
    Code
      req_perform_iterate(req, progress = -1)
    Condition
      Error in `req_perform_iterate()`:
      ! `progress` must be a bool, a string, or a list, not the number -1.

# parse_resp() produces a good error message

    Code
      req_not_a_list$policies$paginate$parse_resp(resp)
    Condition
      Error in `req_not_a_list$policies$paginate$parse_resp()`:
      ! `parse_resp(resp)` must be a list, not the string "a".
    Code
      req_missing_1_field$policies$paginate$parse_resp(resp)
    Condition
      Error in `req_missing_1_field$policies$paginate$parse_resp()`:
      ! The list returned by `parse_resp(resp)` is missing the field next_url.
    Code
      req_missing_2_field$policies$paginate$parse_resp(resp)
    Condition
      Error in `req_missing_2_field$policies$paginate$parse_resp()`:
      ! The list returned by `parse_resp(resp)` is missing the fields next_url and data.

---

    Code
      req_perform_iterate(req, max_pages = 2)
    Condition
      Error in `parse_resp()`:
      ! The list returned by `parse_resp(resp)` is missing the field next_token.

# req_perform_iterate() handles error in `parse_resp()`

    Code
      req_perform_iterate(req, max_pages = 2)
    Condition
      Error in `parse_resp()`:
      ! error

