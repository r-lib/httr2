# httr2 0.2.3

* New `example_url()` to launch a local server, making tests and examples 
  more robust.

* New `throttle_status()` to make it a little easier to verify what's happening
  with throttling.

* `req_oauth_refresh()` now respects the `refresh_token` for caching 
  (@mgirlich, #178).

* `req_perform()` now always sleeps before a request, rather than after it.
  It also gains an `error_call` argument and communicates more clearly
  where the error occurred (@mgirlich, #187).

* `req_url_path()` and `req_url_path_append()` can now handle `NULL` or empty
  `...` and the elements of `...` can also have length > 1 (@mgirlich, #177).

* `sys_sleep()` (used by `req_retry()` and `req_throttle()`) gains a progress 
  bar (#202).
  
# httr2 0.2.2

* `curl_translate()` can now handle curl copied from Chrome developer tools
  (@mgirlich, #161).

* `req_oauth_*()` can now refresh OAuth tokens. One, two, or even more times! 
  (@jennybc, #166)

* `req_oauth_device()` can now work in non-interactive environments,
  as intendend (@flahn, #170)

* `req_oauth_refresh()` and `oauth_flow_refresh()` now use the envvar 
  `HTTR2_REFRESH_TOKEN`, not `HTTR_REFRESH_TOKEN` (@jennybc, #169).

* `req_proxy()` now uses the appropriate authentication option (@jl5000).

* `req_url_query()` can now opt out of escaping with `I()` (@boshek, #152).

* Can now print responses where content type is the empty string 
  (@mgirlich, #163).

# httr2 0.2.1

* "Wrapping APIs" is now an article, not a vignette.

* `req_template()` now appends the path instead of replacing it (@jchrom, #133)

# httr2 0.2.0

## New features

* `req_body_form()`, `req_body_multipart()`, and `req_url_query()` now 
  support multiple arguments with the same name (#97, #107).

* `req_body_form()`, `req_body_multipart()`, now match the interface of 
  `req_url_query()`, taking name-value pairs in `...`. Supplying a single
  `list()` is now deprecated and will be removed in a future version.

* `req_body_json()` now overrides the existing JSON body, rather than 
  attempting to merge with the previous value (#95, #115).

* Implement `req_proxy()` (owenjonesuob, #77).

## Minor improvements and bug fixes

* `httr_path` class renamed to `httr2_path` to correctly match package name 
  (#99).
  
* `oauth_flow_device()` gains PKCE support (@flahn, #92), and 
  the interactive flow is a little more user friendly.

* `req_error()` can now correct force successful HTTP statuses to fail (#98).

* `req_headers()` will now override `Content-Type` set by `req_body_*()` (#116).

* `req_throttle()` correctly sets throttle rate (@jchrom, #101).

* `req_url_query()` never uses scientific notation for queries (#93).

* `req_perform()` now respects `httr::with_verbose()` (#85).

* `response()` now defaults `body` to `raw(0)` for consistency with real
  responses (#100).
  
* `req_stream()` no longer throws an error for non 200 http status codes (@DMerch, #137)
  
# httr2 0.1.1

* Fix R CMD check failures on CRAN

* Added a `NEWS.md` file to track changes to the package.
