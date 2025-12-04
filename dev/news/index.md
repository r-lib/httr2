# Changelog

## httr2 (development version)

- [`req_perform_connection()`](https://httr2.r-lib.org/dev/reference/req_perform_connection.md)
  no longer errors with
  `no applicable method for 'close' applied to an object of class "c('httr2_failure', 'httr2_error', 'rlang_error', 'error', 'condition')`
  ([\#817](https://github.com/r-lib/httr2/issues/817)).
- Refactor
  [`url_modify()`](https://httr2.r-lib.org/dev/reference/url_modify.md)
  to better retain exact formatting of URL components that are not
  modified. ([\#788](https://github.com/r-lib/httr2/issues/788),
  [\#794](https://github.com/r-lib/httr2/issues/794))

## httr2 1.2.1

CRAN release: 2025-07-22

- Colons in paths are no longer escaped.

## httr2 1.2.0

CRAN release: 2025-07-13

### Lifecycle changes

- [`req_perform_stream()`](https://httr2.r-lib.org/dev/reference/req_perform_stream.md)
  has been soft deprecated in favour of
  [`req_perform_connection()`](https://httr2.r-lib.org/dev/reference/req_perform_connection.md).

- Deprecated functions `mutli_req_perform()`, `req_stream()`,
  `with_mock()` and `local_mock()` have been removed.

- Deprecated arguments `req_perform_parallel(pool)`,
  `req_oauth_auth_code(host_name, host_ip, port)`, and
  `oauth_flow_auth_code(host_name, host_ip, port)` have been removed.

### New features

- Redacted headers are no longer serialized to disk. This is important
  since it makes it harder to accidentally leak secrets to files on
  disk, but comes at a cost: you can no longer perform such requests
  that have been saved and reloaded
  ([\#721](https://github.com/r-lib/httr2/issues/721)).

- URL construction is now powered by
  [`curl::curl_modify_url()`](https://jeroen.r-universe.dev/curl/reference/curl_parse_url.html),
  and hence now (correctly) escapes the `path` component
  ([\#732](https://github.com/r-lib/httr2/issues/732)). This means that
  [`req_url_path()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  now can only affect the path component of the URL, not the query
  params or fragment.

- New
  [`last_request_json()`](https://httr2.r-lib.org/dev/reference/last_response.md)
  and
  [`last_response_json()`](https://httr2.r-lib.org/dev/reference/last_response.md)
  to conveniently see JSON bodies
  ([\#734](https://github.com/r-lib/httr2/issues/734)).

- New
  [`req_get_url()`](https://httr2.r-lib.org/dev/reference/req_get_url.md),
  [`req_get_method()`](https://httr2.r-lib.org/dev/reference/req_get_method.md),
  [`req_get_headers()`](https://httr2.r-lib.org/dev/reference/req_get_headers.md),
  `req_body_get_type()`, and
  [`req_get_body()`](https://httr2.r-lib.org/dev/reference/req_get_body_type.md)
  allow you to introspect a request object
  ([\#718](https://github.com/r-lib/httr2/issues/718)).

- New
  [`resp_timing()`](https://httr2.r-lib.org/dev/reference/resp_timing.md)
  exposes timing information about the request measured by libcurl
  ([@arcresu](https://github.com/arcresu),
  [\#725](https://github.com/r-lib/httr2/issues/725)).

### Minor improvements and bug fixes

- Functions that capture interrupts (like
  [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md)
  and friends) are now easier to escape if they’re called inside a loop:
  you can press Ctrl + C twice to guarantee an exit
  ([\#1810](https://github.com/r-lib/httr2/issues/1810)).

- [`req_perform_iterative()`](https://httr2.r-lib.org/dev/reference/req_perform_iterative.md),
  [`req_perform_sequential()`](https://httr2.r-lib.org/dev/reference/req_perform_sequential.md),
  [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md),
  [`req_perform_promise()`](https://httr2.r-lib.org/dev/reference/req_perform_promise.md),
  and
  [`req_perform_connection()`](https://httr2.r-lib.org/dev/reference/req_perform_connection.md)
  now support mocking
  ([\#651](https://github.com/r-lib/httr2/issues/651)). To mock the
  response from
  [`req_perform_connection()`](https://httr2.r-lib.org/dev/reference/req_perform_connection.md)
  create a response with the new `StreamingBody` for a body.

- [`new_response()`](https://httr2.r-lib.org/dev/reference/new_response.md)
  is now exported ([\#751](https://github.com/r-lib/httr2/issues/751)).

- [`req_body_json()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  and
  [`req_body_form()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  correctly unobfuscated inputs, as documented
  ([\#754](https://github.com/r-lib/httr2/issues/754)).

- [`req_body_json_modify()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  can now be used on a request with an empty body.

- [`req_error()`](https://httr2.r-lib.org/dev/reference/req_error.md)
  errors with long bodies are now correctly wrapped
  ([\#727](https://github.com/r-lib/httr2/issues/727)).

- [`req_oauth_device()`](https://httr2.r-lib.org/dev/reference/req_oauth_device.md)
  gains an `open_browser` argument that lets you take control of whether
  a browser is opened or the URL is printed
  ([@plietar](https://github.com/plietar),
  [\#763](https://github.com/r-lib/httr2/issues/763))

- [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md)
  handles `progress` argument consistently with other functions
  ([\#726](https://github.com/r-lib/httr2/issues/726)).

- [`req_url_query()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  now re-calculates n lengths when using `.multi = "explode"` to avoid
  select/recycling issues ([@Kevanness](https://github.com/Kevanness),
  [\#719](https://github.com/r-lib/httr2/issues/719)).

- All print methods now send output to stdout, not the message stream.

## httr2 1.1.2

CRAN release: 2025-03-26

- [`req_headers()`](https://httr2.r-lib.org/dev/reference/req_headers.md)
  more carefully checks its input types
  ([\#707](https://github.com/r-lib/httr2/issues/707)).
- Fix AWS request signing due to `argument 'cache' is missing` error
  ([\#706](https://github.com/r-lib/httr2/issues/706),
  [@jcheng5](https://github.com/jcheng5)).

## httr2 1.1.1

CRAN release: 2025-03-08

### New features

- [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md)
  lifts many of the previous restrictions. It supports simplified
  versions of
  [`req_throttle()`](https://httr2.r-lib.org/dev/reference/req_throttle.md)
  and
  [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md),
  can refresh OAuth tokens, and checks the cache before/after each
  request. ([\#681](https://github.com/r-lib/httr2/issues/681)).
- Default verbosity can be controlled by the `HTTR2_VERBOSITY`
  environment variable
  ([\#687](https://github.com/r-lib/httr2/issues/687)).
- [`local_verbosity()`](https://httr2.r-lib.org/dev/reference/with_verbosity.md)
  matches the existing
  [`with_verbosity()`](https://httr2.r-lib.org/dev/reference/with_verbosity.md)
  and allows for local control of verbosity
  ([\#687](https://github.com/r-lib/httr2/issues/687)).
- [`req_dry_run()`](https://httr2.r-lib.org/dev/reference/req_dry_run.md)
  and
  [`req_verbose()`](https://httr2.r-lib.org/dev/reference/req_verbose.md)
  display compressed correctly
  ([\#91](https://github.com/r-lib/httr2/issues/91),
  [\#656](https://github.com/r-lib/httr2/issues/656)) and automatically
  prettify JSON bodies
  ([\#668](https://github.com/r-lib/httr2/issues/668)). You can suppress
  prettification with `options(httr2_pretty_json = FALSE)`
  ([\#668](https://github.com/r-lib/httr2/issues/668)).
- [`req_throttle()`](https://httr2.r-lib.org/dev/reference/req_throttle.md)
  implements a new “token bucket” algorithm that maintains average rate
  limits while allowing bursts of higher request rates.

### Minor improvements and bug fixes

- `aws_v4_signature()` correctly processes URLs containing query
  parameters ([@jeffreyzuber](https://github.com/jeffreyzuber),
  [\#645](https://github.com/r-lib/httr2/issues/645)).
- [`oauth_client()`](https://httr2.r-lib.org/dev/reference/oauth_client.md)
  and
  [`oauth_token()`](https://httr2.r-lib.org/dev/reference/oauth_token.md)
  implement improved print methods with bulleted lists, similar to other
  httr2 objects, and
  [`oauth_client()`](https://httr2.r-lib.org/dev/reference/oauth_client.md)
  with custom `auth` functions no longer produces errors
  ([\#648](https://github.com/r-lib/httr2/issues/648)).
- [`req_dry_run()`](https://httr2.r-lib.org/dev/reference/req_dry_run.md)
  omits headers that would vary in tests and can prettify JSON output.
- [`req_headers()`](https://httr2.r-lib.org/dev/reference/req_headers.md)
  automatically redacts `Authorization` headers
  ([\#649](https://github.com/r-lib/httr2/issues/649)) and correctly
  implements case-insensitive modification of existing headers
  ([\#682](https://github.com/r-lib/httr2/issues/682)).
- [`req_headers_redacted()`](https://httr2.r-lib.org/dev/reference/req_headers.md)
  now supports dynamic dots
  ([\#647](https://github.com/r-lib/httr2/issues/647)).
- [`req_oauth_auth_code()`](https://httr2.r-lib.org/dev/reference/req_oauth_auth_code.md)
  no longer adds trailing “/” characters to properly formed
  `redirect_uri` values ([@jonthegeek](https://github.com/jonthegeek),
  [\#646](https://github.com/r-lib/httr2/issues/646)).
- [`req_perform_connection()`](https://httr2.r-lib.org/dev/reference/req_perform_connection.md)
  produces more helpful error messages when requests fail at the
  networking level.
- `req_perform_parallel(pool)` now is deprecated in favour of a new
  `max_active` argument
  ([\#681](https://github.com/r-lib/httr2/issues/681)).
- [`req_user_agent()`](https://httr2.r-lib.org/dev/reference/req_user_agent.md)
  memoizes the default user agent to improve performance, as computing
  version numbers is relatively slow (300 µs).
- [`resp_link_url()`](https://httr2.r-lib.org/dev/reference/resp_link_url.md)
  once again respects the case insensitivity for header names
  ([@DavidRLovell](https://github.com/DavidRLovell),
  [\#655](https://github.com/r-lib/httr2/issues/655)).
- [`resp_stream_sse()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md)
  automatically retrieves the next event when the current event contains
  no data, and returns data as a single string
  ([\#650](https://github.com/r-lib/httr2/issues/650)).
- [`str()`](https://rdrr.io/r/utils/str.html) correctly redacts redacted
  headers ([\#682](https://github.com/r-lib/httr2/issues/682)).

## httr2 1.1.0

CRAN release: 2025-01-18

### Lifecycle changes

- [`req_perform_stream()`](https://httr2.r-lib.org/dev/reference/req_perform_stream.md)
  is superseded in favor of
  [`req_perform_connection()`](https://httr2.r-lib.org/dev/reference/req_perform_connection.md),
  which is no longer experimental
  ([\#625](https://github.com/r-lib/httr2/issues/625)).

- `with_mock()` and `local_mock()` are defunct and will be removed in
  the next release.

### New features

- [`is_online()`](https://httr2.r-lib.org/dev/reference/is_online.md)
  wraps
  [`curl::has_internet()`](https://jeroen.r-universe.dev/curl/reference/nslookup.html),
  making it easy to tell if you’re currently online
  ([\#512](https://github.com/r-lib/httr2/issues/512)).

- [`req_headers_redacted()`](https://httr2.r-lib.org/dev/reference/req_headers.md)
  makes it easier to redact sensitive headers
  ([\#561](https://github.com/r-lib/httr2/issues/561)).

- [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md)
  implements “circuit breaking”, which immediatelys error after multiple
  failures to the same server (e.g. because the server is down)
  ([\#370](https://github.com/r-lib/httr2/issues/370)).

- [`req_url_relative()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  navigates to a relative URL
  ([\#449](https://github.com/r-lib/httr2/issues/449)).

- [`resp_request()`](https://httr2.r-lib.org/dev/reference/resp_request.md)
  returns the request associated with a response; this can be useful
  when debugging ([\#604](https://github.com/r-lib/httr2/issues/604)).

- [`resp_stream_is_complete()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md)
  checks if data remains in the stream
  ([\#559](https://github.com/r-lib/httr2/issues/559)).

- [`url_modify()`](https://httr2.r-lib.org/dev/reference/url_modify.md),
  [`url_modify_query()`](https://httr2.r-lib.org/dev/reference/url_modify.md),
  and
  [`url_modify_relative()`](https://httr2.r-lib.org/dev/reference/url_modify.md)
  modify URLs ([\#464](https://github.com/r-lib/httr2/issues/464));
  [`url_query_parse()`](https://httr2.r-lib.org/dev/reference/url_query_parse.md)
  and
  [`url_query_build()`](https://httr2.r-lib.org/dev/reference/url_query_parse.md)
  parse and build query strings
  ([\#425](https://github.com/r-lib/httr2/issues/425)).

### Bug fixes and minor improvements

- OAuth response parsing errors now have a dedicated `httr2_oauth_parse`
  error class that includes the original response object
  ([@atheriel](https://github.com/atheriel),
  [\#596](https://github.com/r-lib/httr2/issues/596)).

- [`curl_translate()`](https://httr2.r-lib.org/dev/reference/curl_translate.md)
  converts cookie headers to
  [`req_cookies_set()`](https://httr2.r-lib.org/dev/reference/req_cookie_preserve.md)
  ([\#431](https://github.com/r-lib/httr2/issues/431)) and JSON data to
  [`req_body_json_modify()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  calls ([\#258](https://github.com/r-lib/httr2/issues/258)).

- `print.request()` escapes [`{}`](https://rdrr.io/r/base/Paren.html) in
  headers ([\#586](https://github.com/r-lib/httr2/issues/586)).

- [`req_auth_aws_v4()`](https://httr2.r-lib.org/dev/reference/req_auth_aws_v4.md)
  formats the AWS Authorization header correctly
  ([\#627](https://github.com/r-lib/httr2/issues/627)).

- [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md)
  defaults to `max_tries = 2` when nethier `max_tries` nor `max_seconds`
  is set. If you want to disable retries, set `max_tries = 1`.

- [`req_perform_connection()`](https://httr2.r-lib.org/dev/reference/req_perform_connection.md)
  gains a `verbosity` argument, which is useful for understanding
  exactly how data is streamed back to you
  ([\#599](https://github.com/r-lib/httr2/issues/599)).
  [`req_perform_promise()`](https://httr2.r-lib.org/dev/reference/req_perform_promise.md)
  also gains a `verbosity` argument.

- [`req_url_query()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  can control how spaces are encoded with `.space`
  ([\#432](https://github.com/r-lib/httr2/issues/432)).

- [`resp_link_url()`](https://httr2.r-lib.org/dev/reference/resp_link_url.md)
  handles multiple `Link` headers
  ([\#587](https://github.com/r-lib/httr2/issues/587)).

- [`resp_stream_sse()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md)
  will warn if it recieves a partial event.

- [`url_parse()`](https://httr2.r-lib.org/dev/reference/url_parse.md)
  parses relative URLs with new `base_url` argument
  ([\#449](https://github.com/r-lib/httr2/issues/449)) and the uses
  faster and more correct
  [`curl::curl_parse_url()`](https://jeroen.r-universe.dev/curl/reference/curl_parse_url.html)
  ([\#577](https://github.com/r-lib/httr2/issues/577)).

## httr2 1.0.7

CRAN release: 2024-11-26

- [`req_perform_promise()`](https://httr2.r-lib.org/dev/reference/req_perform_promise.md)
  upgraded to use event-driven async based on waiting efficiently on
  curl socket activity
  ([\#579](https://github.com/r-lib/httr2/issues/579)).
- New
  [`req_oauth_token_exchange()`](https://httr2.r-lib.org/dev/reference/req_oauth_token_exchange.md)
  and
  [`oauth_flow_token_exchange()`](https://httr2.r-lib.org/dev/reference/req_oauth_token_exchange.md)
  functions implement the OAuth token exchange protocol from RFC 8693
  ([@atheriel](https://github.com/atheriel),
  [\#460](https://github.com/r-lib/httr2/issues/460)).

## httr2 1.0.6

CRAN release: 2024-11-04

- Fix stochastic test failure, particularly on CRAN
  ([\#572](https://github.com/r-lib/httr2/issues/572))
- New
  [`oauth_cache_clear()`](https://httr2.r-lib.org/dev/reference/oauth_cache_clear.md)
  is an exported end point to clear the OAuth cache.
- New
  [`req_auth_aws_v4()`](https://httr2.r-lib.org/dev/reference/req_auth_aws_v4.md)
  signs request using AWS’s special format
  ([\#562](https://github.com/r-lib/httr2/issues/562),
  [\#566](https://github.com/r-lib/httr2/issues/566)).
- [`req_cache()`](https://httr2.r-lib.org/dev/reference/req_cache.md) no
  longer retrieves anything but `GET` requests from the cache.
- New
  [`resp_stream_aws()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md)
  to retrieve AWS’s special streaming format. With thanks to
  <https://github.com/lifion/lifion-aws-event-stream/> for a simple
  reference implementation.

## httr2 1.0.5

CRAN release: 2024-09-26

- [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md)
  and
  [`req_perform_promise()`](https://httr2.r-lib.org/dev/reference/req_perform_promise.md)
  now correctly set up the method and body
  ([\#549](https://github.com/r-lib/httr2/issues/549)).

## httr2 1.0.4

CRAN release: 2024-09-13

- [`req_body_file()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  now works with files \>64kb once more
  ([\#524](https://github.com/r-lib/httr2/issues/524)) and no longer
  leaks a connection if the response doesn’t complete succesfully
  ([\#534](https://github.com/r-lib/httr2/issues/534)).
- `req_body_*()` now give informative error if you attempt to change the
  body type ([\#451](https://github.com/r-lib/httr2/issues/451)).
- [`req_cache()`](https://httr2.r-lib.org/dev/reference/req_cache.md)
  now re-caches the response if the body is hasn’t been modified but the
  headers have changed
  ([\#442](https://github.com/r-lib/httr2/issues/442)). It also works
  better when
  [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
  sets a path ([\#442](https://github.com/r-lib/httr2/issues/442)).
- New `req_cookie_set()` allows you to set client side cookies
  ([\#369](https://github.com/r-lib/httr2/issues/369)).
- [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
  no longer displays a progress bar when sleeping during tests. You can
  override this behaviour by setting the option `httr2_progress`.
- [`req_perform_iterative()`](https://httr2.r-lib.org/dev/reference/req_perform_iterative.md)
  is no longer experimental.
- New
  [`req_perform_connection()`](https://httr2.r-lib.org/dev/reference/req_perform_connection.md)
  for working with streaming data. Unlike
  [`req_perform_stream()`](https://httr2.r-lib.org/dev/reference/req_perform_stream.md)
  which uses callbacks,
  [`req_perform_connection()`](https://httr2.r-lib.org/dev/reference/req_perform_connection.md)
  returns a regular response object with a connection as the body.
  Unlike
  [`req_perform_stream()`](https://httr2.r-lib.org/dev/reference/req_perform_stream.md)
  it supports
  [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md)
  (with [@jcheng5](https://github.com/jcheng5),
  [\#519](https://github.com/r-lib/httr2/issues/519)).
- [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md) no
  longer treates low-level HTTP failures the same way as transient
  errors by default. You can return to the previous behaviour with
  `retry_on_error = TRUE`.
- [`resp_body_html()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md)
  and
  [`resp_body_xml()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md)
  now work when
  [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
  is given a path ([\#448](https://github.com/r-lib/httr2/issues/448)).
- New `resp_stream_bytes()`,
  [`resp_stream_lines()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md),
  and
  [`resp_stream_sse()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md)
  for streaming chunk from a connection response
  ([\#519](https://github.com/r-lib/httr2/issues/519)).

## httr2 1.0.3

CRAN release: 2024-08-22

- [`jwt_encode_hmac()`](https://httr2.r-lib.org/dev/reference/jwt_claim.md)
  now calls correct underlying function
  [`jose::jwt_encode_hmac()`](https://r-lib.r-universe.dev/jose/reference/jwt_encode.html)
  and has correct default size parameter value
  ([@denskh](https://github.com/denskh),
  [\#508](https://github.com/r-lib/httr2/issues/508)).

- [`req_cache()`](https://httr2.r-lib.org/dev/reference/req_cache.md)
  now prunes cache *before* checking if a given key exists, eliminating
  the occassional error about reading from an invalid RDS file. It also
  no longer tests for existence then later reads the cache, avoiding
  potential race conditions.

- New
  [`req_perform_promise()`](https://httr2.r-lib.org/dev/reference/req_perform_promise.md)
  creates a
  [`promises::promise`](https://rstudio.github.io/promises/reference/promise.html)
  so a request can run in the background
  ([\#501](https://github.com/r-lib/httr2/issues/501),
  [@gergness](https://github.com/gergness)).

- [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md)
  now respects error handling in
  [`req_error()`](https://httr2.r-lib.org/dev/reference/req_error.md).

## httr2 1.0.2

CRAN release: 2024-07-16

- [`req_body_file()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  now only opens a connection when the request actually needs data. In
  particular, this makes it work better with
  [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md)
  ([\#487](https://github.com/r-lib/httr2/issues/487)).
- [`req_cache()`](https://httr2.r-lib.org/dev/reference/req_cache.md) no
  longer fails if the `rds` files are somehow corrupted and now defaults
  the `debug` argument to the `httr2_cache_debug` option to make it
  easier to debug caching buried in other people’s code
  ([\#486](https://github.com/r-lib/httr2/issues/486)).
- [`req_oauth_password()`](https://httr2.r-lib.org/dev/reference/req_oauth_password.md)
  now only asks for your password once
  ([\#498](https://github.com/r-lib/httr2/issues/498)).
- [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md)
  now works correctly with
  [`req_cache()`](https://httr2.r-lib.org/dev/reference/req_cache.md)
  ([\#447](https://github.com/r-lib/httr2/issues/447)) and now works
  when downloading 0 byte files
  ([\#478](https://github.com/r-lib/httr2/issues/478))
- [`req_perform_stream()`](https://httr2.r-lib.org/dev/reference/req_perform_stream.md)
  no longer applies the `callback` to unsuccessful responses, instead
  creating a regular response. It also now sets
  [`last_request()`](https://httr2.r-lib.org/dev/reference/last_response.md)
  and
  [`last_response()`](https://httr2.r-lib.org/dev/reference/last_response.md)
  ([\#479](https://github.com/r-lib/httr2/issues/479)).
- [`req_url_query()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  now allows you to opt out of escaping for multi-value parameters
  ([\#404](https://github.com/r-lib/httr2/issues/404)).

## httr2 1.0.1

CRAN release: 2024-04-01

- [`req_perform_stream()`](https://httr2.r-lib.org/dev/reference/req_perform_stream.md)
  gains a `round = c("byte", "line")` argument to control how the stream
  is rounded ([\#437](https://github.com/r-lib/httr2/issues/437)).

- [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md)
  gives a clearer error if `after` returns the wrong type of value
  ([\#385](https://github.com/r-lib/httr2/issues/385)).

- [`req_template()`](https://httr2.r-lib.org/dev/reference/req_template.md)
  now works when you have a bare `:` in a template that uses “uri” style
  ([\#389](https://github.com/r-lib/httr2/issues/389)).

- [`req_timeout()`](https://httr2.r-lib.org/dev/reference/req_timeout.md)
  now resets the value of `connecttimeout` set by curl. This ensures
  that you can use
  [`req_timeout()`](https://httr2.r-lib.org/dev/reference/req_timeout.md)
  to increase the connection timeout past 10s
  ([\#395](https://github.com/r-lib/httr2/issues/395)).

- [`url_parse()`](https://httr2.r-lib.org/dev/reference/url_parse.md) is
  considerably faster thanks to performance optimisations by and
  discussion with [@DyfanJones](https://github.com/DyfanJones)
  ([\#429](https://github.com/r-lib/httr2/issues/429)).

## httr2 1.0.0

CRAN release: 2023-11-14

### Function lifecycle

- `local_mock()` and `with_mock()` have been deprecated in favour of
  [`local_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)
  and
  [`with_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)
  ([\#301](https://github.com/r-lib/httr2/issues/301)).

- `multi_req_perform()` is deprecated in favour of
  [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md).
  `req_stream()` is deprecated in favour of
  [`req_perform_stream()`](https://httr2.r-lib.org/dev/reference/req_perform_stream.md)
  ([\#314](https://github.com/r-lib/httr2/issues/314)).

- [`oauth_flow_auth_code()`](https://httr2.r-lib.org/dev/reference/req_oauth_auth_code.md)
  deprecates `host_name` and `port` arguments in favour of using
  `redirect_uri`. It also deprecates `host_ip` since it seems unlikely
  that changing this is ever useful.

- [`oauth_flow_auth_code_listen()`](https://httr2.r-lib.org/dev/reference/oauth_flow_auth_code_url.md)
  now takes a single `redirect_uri` argument instead of separate
  `host_ip` and `port` arguments. This is a breaking change but I don’t
  expect anyone to call this function directly (which was confirmed by a
  GitHub search) so I made the change without deprecation.

- [`req_body_form()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  and
  [`req_body_multipart()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  now require data `...`; they no longer accept a single list for
  compatibility with the 0.1.0 API.

### Multiple requests

- New
  [`req_perform_sequential()`](https://httr2.r-lib.org/dev/reference/req_perform_sequential.md)
  performs a known set of requests sequentially. It has an interface
  similar to
  [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md)
  but with no limitations, and the cost of being slower
  ([\#361](https://github.com/r-lib/httr2/issues/361)).

- New
  [`req_perform_iterative()`](https://httr2.r-lib.org/dev/reference/req_perform_iterative.md)
  performs multiple requests, where each request is derived from the
  previous response ([@mgirlich](https://github.com/mgirlich),
  [\#8](https://github.com/r-lib/httr2/issues/8)).

- [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md)
  replaces `multi_req_perform()` to match the new naming scheme
  ([\#314](https://github.com/r-lib/httr2/issues/314)). It gains a
  `progress` argument.

- [`req_perform_iterative()`](https://httr2.r-lib.org/dev/reference/req_perform_iterative.md),
  [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md),
  and
  [`req_perform_sequential()`](https://httr2.r-lib.org/dev/reference/req_perform_sequential.md)
  share a new error handling strategy. By default, errors will be
  bubbled up, but you can choose an alternative strategy with the
  `on_error` argument
  ([\#372](https://github.com/r-lib/httr2/issues/372)).

- A new family of functions
  [`resps_successes()`](https://httr2.r-lib.org/dev/reference/resps_successes.md),
  [`resps_failures()`](https://httr2.r-lib.org/dev/reference/resps_successes.md),
  [`resps_requests()`](https://httr2.r-lib.org/dev/reference/resps_successes.md)
  and
  [`resps_data()`](https://httr2.r-lib.org/dev/reference/resps_successes.md)
  make it easier to work with lists of responses
  ([\#357](https://github.com/r-lib/httr2/issues/357)). Behind the
  scenes, these work because the request is now stored in the response
  (or error) object
  ([\#357](https://github.com/r-lib/httr2/issues/357)).

- [`resp_body_json()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md)
  and
  [`resp_body_xml()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md)
  now cache the parsed values so that you can use them repeatedly
  without worrying about the performance cost. This supports the design
  [`req_perform_iterative()`](https://httr2.r-lib.org/dev/reference/req_perform_iterative.md)
  by avoiding the need to carefully pass around a parsed object.

### OAuth features

- A new [OAuth vignette](https://httr2.r-lib.org/articles/oauth.html)
  gives many more details about how OAuth works and how to use it with
  httr2 ([\#234](https://github.com/r-lib/httr2/issues/234)), and the
  OAuth docs have been overhauled to make it more clear that you should
  use `req_oauth_*()`, not `oauth_*()`
  ([\#330](https://github.com/r-lib/httr2/issues/330)).

- If you are using an OAuth token with a refresh token, and that refresh
  token has expired, then httr2 will now re-run the entire flow to get
  you a new token ([\#349](https://github.com/r-lib/httr2/issues/349)).

- New
  [`oauth_cache_path()`](https://httr2.r-lib.org/dev/reference/oauth_cache_path.md)
  returns the path that httr2 uses for caching OAuth tokens.
  Additionally, you can now change the cache location by setting the
  `HTTR2_OAUTH_CACHE` env var. This is now more obvious to the user,
  because httr2 now informs the user whenever a token is cached.

- [`oauth_flow_auth_code()`](https://httr2.r-lib.org/dev/reference/req_oauth_auth_code.md)
  gains a `redirect_uri` argument rather than deriving this URL
  automatically from the `host_name` and `port`
  ([\#248](https://github.com/r-lib/httr2/issues/248)). It uses this
  argument to automatically choose which strategy to use to get the auth
  code, either launching a temporary web server or, new, allowing you to
  manually enter the details with the help of a custom JS/HTML page
  hosted elsewhere, or by copying and pasting the URL you’re redirected
  to ([@fh-mthomson](https://github.com/fh-mthomson),
  [\#326](https://github.com/r-lib/httr2/issues/326)). The temporary web
  server now also respects the path component of `redirect_uri`, if the
  API needs a specific path
  ([\#149](https://github.com/r-lib/httr2/issues/149)).

- New
  [`oauth_token_cached()`](https://httr2.r-lib.org/dev/reference/oauth_token_cached.md)
  allows you to get an OAuth token while still taking advantage of
  httr2’s caching and auto-renewal features. For expert use only
  ([\#328](https://github.com/r-lib/httr2/issues/328)).

### Other new features

- [@mgirlich](https://github.com/mgirlich) is now a httr2 contributor in
  recognition of his many contributions.

- [`req_cache()`](https://httr2.r-lib.org/dev/reference/req_cache.md)
  gains `max_n`, `max_size`, and `max_age` arguments to automatically
  prune the cache. By default, the cache will stay under 1 GB
  ([\#207](https://github.com/r-lib/httr2/issues/207)).

- New
  [`req_body_json_modify()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  allows you to iteratively modify a JSON body of a request.

- New
  [`req_cookie_preserve()`](https://httr2.r-lib.org/dev/reference/req_cookie_preserve.md)
  lets you use a file to share cookies across requests
  ([\#223](https://github.com/r-lib/httr2/issues/223)).

- New
  [`req_progress()`](https://httr2.r-lib.org/dev/reference/req_progress.md)
  adds a progress bar to long downloads or uploads
  ([\#20](https://github.com/r-lib/httr2/issues/20)).

- New
  [`resp_check_content_type()`](https://httr2.r-lib.org/dev/reference/resp_check_content_type.md)
  to check response content types
  ([\#190](https://github.com/r-lib/httr2/issues/190)).
  [`resp_body_json()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md)
  and friends give better errors if no `Content-Type` header is present
  in the response ([\#284](https://github.com/r-lib/httr2/issues/284)).

- New
  [`resp_has_body()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md)
  returns a `TRUE` or `FALSE` depending on whether or not the response
  has a body ([\#205](https://github.com/r-lib/httr2/issues/205)).

- New [`resp_url()`](https://httr2.r-lib.org/dev/reference/resp_url.md),
  [`resp_url_path()`](https://httr2.r-lib.org/dev/reference/resp_url.md),
  [`resp_url_queries()`](https://httr2.r-lib.org/dev/reference/resp_url.md)
  and
  [`resp_url_query()`](https://httr2.r-lib.org/dev/reference/resp_url.md)
  to extract various part of the response url
  ([\#57](https://github.com/r-lib/httr2/issues/57)).

- [`req_url_query()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  gains a `.multi` parameter that controls what happens when you supply
  multiple values in a vector. The default will continue to error but
  you can use `.multi = "comma"` to separate with commas, `"pipe"` to
  separate with `|`, and `"explode"` to generate one parameter for each
  value (e.g. `?a=1&a=2`)
  ([\#350](https://github.com/r-lib/httr2/issues/350)).

- New
  [`secret_encrypt_file()`](https://httr2.r-lib.org/dev/reference/secrets.md)
  and
  [`secret_decrypt_file()`](https://httr2.r-lib.org/dev/reference/secrets.md)
  for encrypting and decrypting files
  ([\#237](https://github.com/r-lib/httr2/issues/237)).

### Minor improvements and bug fixes

- The httr2 examples now only run on R 4.2 and later so that we can use
  the base pipe and lambda syntax
  ([\#345](https://github.com/r-lib/httr2/issues/345)).

- OAuth errors containing a url now correctly display that URL (instead
  of the string “uri”).

- [`curl_translate()`](https://httr2.r-lib.org/dev/reference/curl_translate.md)
  now uses the base pipe, and produces escapes with single quotes or raw
  strings in case double quotes can’t be used
  ([@mgirlich](https://github.com/mgirlich),
  [\#264](https://github.com/r-lib/httr2/issues/264)). It gains the
  argument `simplify_headers` that removes some common but unimportant
  headers, like `Sec-Fetch-Dest` or `sec-ch-ua-mobile`
  ([@mgirlich](https://github.com/mgirlich),
  [\#256](https://github.com/r-lib/httr2/issues/256)). It also parses
  the query components of the url
  ([@mgirlich](https://github.com/mgirlich),
  [\#259](https://github.com/r-lib/httr2/issues/259)) and works with
  multiline commands from the clipboard
  ([@mgirlich](https://github.com/mgirlich),
  [\#254](https://github.com/r-lib/httr2/issues/254)).

- [`local_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)
  and
  [`with_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)
  now accept a list of responses which will be returned in sequence.
  They also now correctly trigger errors when the mocked response
  represents an HTTP failure
  ([\#252](https://github.com/r-lib/httr2/issues/252)).

- [`oauth_flow_refresh()`](https://httr2.r-lib.org/dev/reference/req_oauth_refresh.md)
  now only warns, not errors, if the `refresh_token` changes, making it
  a little easier to use in manual workflows
  ([\#186](https://github.com/r-lib/httr2/issues/186)).

- [`obfuscated()`](https://httr2.r-lib.org/dev/reference/obfuscate.md)
  values now display their original call when printed.

- [`req_body_json()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  gains custom content `type` argument and respects custom content-type
  set in header ([@mgirlich](https://github.com/mgirlich),
  [\#189](https://github.com/r-lib/httr2/issues/189)).

- [`req_cache()`](https://httr2.r-lib.org/dev/reference/req_cache.md)
  now combine the headers of the new response with the headers of the
  cached response. In particular, this fixes `resp_body_json/xml/html()`
  on cached responses ([@mgirlich](https://github.com/mgirlich),
  [\#277](https://github.com/r-lib/httr2/issues/277)).

- [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
  now throws error with class `httr2_failure/httr2_error` if the request
  fails, and that error now captures the curl error as the parent. If
  the request succeeds, but the response is an HTTP error, that error
  now also has super class `httr2_error`. This means that all errors
  thrown by httr2 now inherit from the `httr2_error` class. See new docs
  in `?req_error()` for more details.

- [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)’s
  progress bar can be suppressed by setting
  `options(httr2_progress = FALSE)`
  ([\#251](https://github.com/r-lib/httr2/issues/251)). Progress bars
  displayed while waiting for some time to pass now tell you why they’re
  waiting ([\#206](https://github.com/r-lib/httr2/issues/206)).

- [`req_oauth_bearer_jwt()`](https://httr2.r-lib.org/dev/reference/req_oauth_bearer_jwt.md)
  now includes the claim in the cache key
  ([\#192](https://github.com/r-lib/httr2/issues/192)).

- [`req_oauth_device()`](https://httr2.r-lib.org/dev/reference/req_oauth_device.md)
  now takes a `auth_url` parameter making it usable
  ([\#331](https://github.com/r-lib/httr2/issues/331),
  [@taerwin](https://github.com/taerwin)).

- [`req_url_query()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  gains a `.multi` parameter that controls what happens when you supply
  multiple values in a vector. The default will continue to error but
  you can use `.multi = "comma"` to separate with commas, `"pipe"` to
  separate with `|`, and `"explode"` to generate one parameter for each
  value (e.g. `?a=1&a=2`)
  ([\#350](https://github.com/r-lib/httr2/issues/350)).

## httr2 0.2.3

CRAN release: 2023-05-08

- New
  [`example_url()`](https://httr2.r-lib.org/dev/reference/example_url.md)
  to launch a local server, making tests and examples more robust.

- New
  [`throttle_status()`](https://httr2.r-lib.org/dev/reference/throttle_status.md)
  to make it a little easier to verify what’s happening with throttling.

- [`req_oauth_refresh()`](https://httr2.r-lib.org/dev/reference/req_oauth_refresh.md)
  now respects the `refresh_token` for caching
  ([@mgirlich](https://github.com/mgirlich),
  [\#178](https://github.com/r-lib/httr2/issues/178)).

- [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
  now always sleeps before a request, rather than after it. It also
  gains an `error_call` argument and communicates more clearly where the
  error occurred ([@mgirlich](https://github.com/mgirlich),
  [\#187](https://github.com/r-lib/httr2/issues/187)).

- [`req_url_path()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  and
  [`req_url_path_append()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  can now handle `NULL` or empty `...` and the elements of `...` can
  also have length \> 1 ([@mgirlich](https://github.com/mgirlich),
  [\#177](https://github.com/r-lib/httr2/issues/177)).

- `sys_sleep()` (used by
  [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md)
  and
  [`req_throttle()`](https://httr2.r-lib.org/dev/reference/req_throttle.md))
  gains a progress bar
  ([\#202](https://github.com/r-lib/httr2/issues/202)).

## httr2 0.2.2

CRAN release: 2022-09-25

- [`curl_translate()`](https://httr2.r-lib.org/dev/reference/curl_translate.md)
  can now handle curl copied from Chrome developer tools
  ([@mgirlich](https://github.com/mgirlich),
  [\#161](https://github.com/r-lib/httr2/issues/161)).

- `req_oauth_*()` can now refresh OAuth tokens. One, two, or even more
  times! ([@jennybc](https://github.com/jennybc),
  [\#166](https://github.com/r-lib/httr2/issues/166))

- [`req_oauth_device()`](https://httr2.r-lib.org/dev/reference/req_oauth_device.md)
  can now work in non-interactive environments, as intendend
  ([@flahn](https://github.com/flahn),
  [\#170](https://github.com/r-lib/httr2/issues/170))

- [`req_oauth_refresh()`](https://httr2.r-lib.org/dev/reference/req_oauth_refresh.md)
  and
  [`oauth_flow_refresh()`](https://httr2.r-lib.org/dev/reference/req_oauth_refresh.md)
  now use the envvar `HTTR2_REFRESH_TOKEN`, not `HTTR_REFRESH_TOKEN`
  ([@jennybc](https://github.com/jennybc),
  [\#169](https://github.com/r-lib/httr2/issues/169)).

- [`req_proxy()`](https://httr2.r-lib.org/dev/reference/req_proxy.md)
  now uses the appropriate authentication option
  ([@jl5000](https://github.com/jl5000)).

- [`req_url_query()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  can now opt out of escaping with
  [`I()`](https://rdrr.io/r/base/AsIs.html)
  ([@boshek](https://github.com/boshek),
  [\#152](https://github.com/r-lib/httr2/issues/152)).

- Can now print responses where content type is the empty string
  ([@mgirlich](https://github.com/mgirlich),
  [\#163](https://github.com/r-lib/httr2/issues/163)).

## httr2 0.2.1

CRAN release: 2022-05-10

- “Wrapping APIs” is now an article, not a vignette.

- [`req_template()`](https://httr2.r-lib.org/dev/reference/req_template.md)
  now appends the path instead of replacing it
  ([@jchrom](https://github.com/jchrom),
  [\#133](https://github.com/r-lib/httr2/issues/133))

## httr2 0.2.0

CRAN release: 2022-04-28

### New features

- [`req_body_form()`](https://httr2.r-lib.org/dev/reference/req_body.md),
  [`req_body_multipart()`](https://httr2.r-lib.org/dev/reference/req_body.md),
  and
  [`req_url_query()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  now support multiple arguments with the same name
  ([\#97](https://github.com/r-lib/httr2/issues/97),
  [\#107](https://github.com/r-lib/httr2/issues/107)).

- [`req_body_form()`](https://httr2.r-lib.org/dev/reference/req_body.md),
  [`req_body_multipart()`](https://httr2.r-lib.org/dev/reference/req_body.md),
  now match the interface of
  [`req_url_query()`](https://httr2.r-lib.org/dev/reference/req_url.md),
  taking name-value pairs in `...`. Supplying a single
  [`list()`](https://rdrr.io/r/base/list.html) is now deprecated and
  will be removed in a future version.

- [`req_body_json()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  now overrides the existing JSON body, rather than attempting to merge
  with the previous value
  ([\#95](https://github.com/r-lib/httr2/issues/95),
  [\#115](https://github.com/r-lib/httr2/issues/115)).

- Implement
  [`req_proxy()`](https://httr2.r-lib.org/dev/reference/req_proxy.md)
  (owenjonesuob, [\#77](https://github.com/r-lib/httr2/issues/77)).

### Minor improvements and bug fixes

- `httr_path` class renamed to `httr2_path` to correctly match package
  name ([\#99](https://github.com/r-lib/httr2/issues/99)).

- [`oauth_flow_device()`](https://httr2.r-lib.org/dev/reference/req_oauth_device.md)
  gains PKCE support ([@flahn](https://github.com/flahn),
  [\#92](https://github.com/r-lib/httr2/issues/92)), and the interactive
  flow is a little more user friendly.

- [`req_error()`](https://httr2.r-lib.org/dev/reference/req_error.md)
  can now correct force successful HTTP statuses to fail
  ([\#98](https://github.com/r-lib/httr2/issues/98)).

- [`req_headers()`](https://httr2.r-lib.org/dev/reference/req_headers.md)
  will now override `Content-Type` set by `req_body_*()`
  ([\#116](https://github.com/r-lib/httr2/issues/116)).

- [`req_throttle()`](https://httr2.r-lib.org/dev/reference/req_throttle.md)
  correctly sets throttle rate ([@jchrom](https://github.com/jchrom),
  [\#101](https://github.com/r-lib/httr2/issues/101)).

- [`req_url_query()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  never uses scientific notation for queries
  ([\#93](https://github.com/r-lib/httr2/issues/93)).

- [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
  now respects
  [`httr::with_verbose()`](https://httr.r-lib.org/reference/with_config.html)
  ([\#85](https://github.com/r-lib/httr2/issues/85)).

- [`response()`](https://httr2.r-lib.org/dev/reference/response.md) now
  defaults `body` to `raw(0)` for consistency with real responses
  ([\#100](https://github.com/r-lib/httr2/issues/100)).

- `req_stream()` no longer throws an error for non 200 http status codes
  ([@DMerch](https://github.com/DMerch),
  [\#137](https://github.com/r-lib/httr2/issues/137))

## httr2 0.1.1

CRAN release: 2021-09-28

- Fix R CMD check failures on CRAN

- Added a `NEWS.md` file to track changes to the package.
