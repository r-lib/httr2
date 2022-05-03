# httr2 (development version)

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
