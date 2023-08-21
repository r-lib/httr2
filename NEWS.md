# httr2 (development version)

* New `req_cookie_file()` lets you use a file to share cookies across 
  requests (#223).

* `url_build()` automatically adds leading `/` to `path` if missing (#276).

* Cached responses now combine the headers of the new response with the headers
  of the cached response. In particular, this fixes `resp_body_json/xml/html()`
  on cached responses (@mgirlich, #277).

* `with_mock()` and `local_mock()` now correctly trigger errors when the
  mocked response represents an HTTP failure (#252).

* New `req_progress()` adds a progress bar to long download or uploads (#20).

* @mgirlich is now a httr2 contributor in recognition of many small contributions.

* `req_headers()` gains a `.redact` argument that controls whether or not to
  redact a header (@mgirlich, #247).

* `req_body_file()` now supports "rewinding". This is occasionally needed when
  you upload a file to a URL that uses a 307 or 308 redirect to state that you 
  should have submitted the file to a different URL, and makes the "necessary 
  data rewind wasn't possible" error go away (#268).

* `curl_translate()` now produces escapes with single quotes or raw strings
  in case double quotes can't be used (@mgirlich, #264).

* `curl_translate()` gains the argument `simplify_headers` that removes some
  common but unimportant headers e.g. `Sec-Fetch-Dest` or `sec-ch-ua-mobile`
  (@mgirlich, #256).
  
* `curl_translate()` now parses the query components of the url (@mgirlich, #259).

* `curl_translate()` now works with multiline commands from the clipboard
  (@mgirlich, #254).

* New `resp_has_body()` returns a `TRUE` or `FALSE` depending on whether
  or not the response has a body (#205).

* Improve print method for responses with body saved to disk.

* `obfuscated()` values now display their original call when printed.

* `resp_header()` gains a `default` argument which is returned if the header
  doesn't exist (#208).

* `oauth_flow_refresh()` now only warns if the `refresh_token` changes, making
  it a little easier to use in manual workflows (#186).

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
