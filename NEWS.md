# httr2 (development version)

* The `oauth_flow_device()` flow is a little more user friendly.

* Implement `req_proxy()` (owenjonesuob, #77).

* `req_body_form()`, `req_body_multipart()`, and `req_url_query()` now 
  support multiple arguments with the same name (#97, #107).

* `req_throttle()` correctly sets throttle rate (@jchrom, #101).

* `req_error()` can now correct force successful HTTP statuses to fail (#98).

* `req_headers()` will now override `Content-Type` set by `req_body_*()` (#116)

* `req_url_query()` never uses scientific notation for queries (#93)

* `req_perform()` now respects `httr::with_verbose()` (#85)

* `response()` now defaults `body` to `raw(0)` for consistency with real
  responses (#100).

* `httr_path` class renamed to `httr2_path` to correctly match package name 
  (#99).

* Added PKCE support to `oauth_flow_device()` (@flahn, #92).

# httr2 0.1.1

* Fix R CMD check failures on CRAN

* Added a `NEWS.md` file to track changes to the package.
