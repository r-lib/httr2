# Package index

## Requests

### Create and modify

- [`request()`](https://httr2.r-lib.org/dev/reference/request.md) :
  Create a new HTTP request
- [`req_body_raw()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  [`req_body_file()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  [`req_body_json()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  [`req_body_json_modify()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  [`req_body_form()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  [`req_body_multipart()`](https://httr2.r-lib.org/dev/reference/req_body.md)
  : Send data in request body
- [`req_cookie_preserve()`](https://httr2.r-lib.org/dev/reference/req_cookie_preserve.md)
  [`req_cookies_set()`](https://httr2.r-lib.org/dev/reference/req_cookie_preserve.md)
  : Set and preserve cookies
- [`req_headers()`](https://httr2.r-lib.org/dev/reference/req_headers.md)
  [`req_headers_redacted()`](https://httr2.r-lib.org/dev/reference/req_headers.md)
  : Modify request headers
- [`req_method()`](https://httr2.r-lib.org/dev/reference/req_method.md)
  : Set HTTP method in request
- [`req_options()`](https://httr2.r-lib.org/dev/reference/req_options.md)
  : Set arbitrary curl options in request
- [`req_progress()`](https://httr2.r-lib.org/dev/reference/req_progress.md)
  : Add a progress bar to long downloads or uploads
- [`req_proxy()`](https://httr2.r-lib.org/dev/reference/req_proxy.md) :
  Use a proxy for a request
- [`req_template()`](https://httr2.r-lib.org/dev/reference/req_template.md)
  : Set request method/path from a template
- [`req_timeout()`](https://httr2.r-lib.org/dev/reference/req_timeout.md)
  : Set time limit for a request
- [`req_url()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  [`req_url_relative()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  [`req_url_query()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  [`req_url_path()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  [`req_url_path_append()`](https://httr2.r-lib.org/dev/reference/req_url.md)
  : Modify request URL
- [`req_user_agent()`](https://httr2.r-lib.org/dev/reference/req_user_agent.md)
  : Set user-agent for a request

### Debugging/testing

- [`last_response()`](https://httr2.r-lib.org/dev/reference/last_response.md)
  [`last_request()`](https://httr2.r-lib.org/dev/reference/last_response.md)
  [`last_request_json()`](https://httr2.r-lib.org/dev/reference/last_response.md)
  [`last_response_json()`](https://httr2.r-lib.org/dev/reference/last_response.md)
  : Retrieve most recent request/response
- [`req_dry_run()`](https://httr2.r-lib.org/dev/reference/req_dry_run.md)
  : Perform a dry run
- [`req_verbose()`](https://httr2.r-lib.org/dev/reference/req_verbose.md)
  : Show extra output when request is performed
- [`with_verbosity()`](https://httr2.r-lib.org/dev/reference/with_verbosity.md)
  [`local_verbosity()`](https://httr2.r-lib.org/dev/reference/with_verbosity.md)
  : Temporarily set verbosity for all requests

### Authentication

- [`req_auth_aws_v4()`](https://httr2.r-lib.org/dev/reference/req_auth_aws_v4.md)
  : Sign a request with the AWS SigV4 signing protocol
- [`req_auth_basic()`](https://httr2.r-lib.org/dev/reference/req_auth_basic.md)
  : Authenticate request with HTTP basic authentication
- [`req_auth_bearer_token()`](https://httr2.r-lib.org/dev/reference/req_auth_bearer_token.md)
  : Authenticate request with bearer token
- [`req_oauth_auth_code()`](https://httr2.r-lib.org/dev/reference/req_oauth_auth_code.md)
  [`oauth_flow_auth_code()`](https://httr2.r-lib.org/dev/reference/req_oauth_auth_code.md)
  : OAuth with authorization code
- [`req_oauth_bearer_jwt()`](https://httr2.r-lib.org/dev/reference/req_oauth_bearer_jwt.md)
  [`oauth_flow_bearer_jwt()`](https://httr2.r-lib.org/dev/reference/req_oauth_bearer_jwt.md)
  : OAuth with a bearer JWT (JSON web token)
- [`req_oauth_client_credentials()`](https://httr2.r-lib.org/dev/reference/req_oauth_client_credentials.md)
  [`oauth_flow_client_credentials()`](https://httr2.r-lib.org/dev/reference/req_oauth_client_credentials.md)
  : OAuth with client credentials
- [`req_oauth_device()`](https://httr2.r-lib.org/dev/reference/req_oauth_device.md)
  [`oauth_flow_device()`](https://httr2.r-lib.org/dev/reference/req_oauth_device.md)
  : OAuth with device flow
- [`req_oauth_password()`](https://httr2.r-lib.org/dev/reference/req_oauth_password.md)
  [`oauth_flow_password()`](https://httr2.r-lib.org/dev/reference/req_oauth_password.md)
  : OAuth with username and password
- [`req_oauth_refresh()`](https://httr2.r-lib.org/dev/reference/req_oauth_refresh.md)
  [`oauth_flow_refresh()`](https://httr2.r-lib.org/dev/reference/req_oauth_refresh.md)
  : OAuth with a refresh token
- [`req_oauth_token_exchange()`](https://httr2.r-lib.org/dev/reference/req_oauth_token_exchange.md)
  [`oauth_flow_token_exchange()`](https://httr2.r-lib.org/dev/reference/req_oauth_token_exchange.md)
  : OAuth token exchange

## Perform a request

- [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
  : Perform a request to get a response
- [`req_perform_stream()`](https://httr2.r-lib.org/dev/reference/req_perform_stream.md)
  **\[deprecated\]** : Perform a request and handle data as it streams
  back
- [`req_perform_connection()`](https://httr2.r-lib.org/dev/reference/req_perform_connection.md)
  : Perform a request and return a streaming connection
- [`req_perform_promise()`](https://httr2.r-lib.org/dev/reference/req_perform_promise.md)
  **\[experimental\]** : Perform request asynchronously using the
  promises package

### Control the process

These functions don’t modify the HTTP request that is sent to the
server, but affect the overall process of
[`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md).

- [`req_cache()`](https://httr2.r-lib.org/dev/reference/req_cache.md) :
  Automatically cache requests
- [`req_error()`](https://httr2.r-lib.org/dev/reference/req_error.md) :
  Control handling of HTTP errors
- [`req_throttle()`](https://httr2.r-lib.org/dev/reference/req_throttle.md)
  : Rate limit a request by automatically adding a delay
- [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md) :
  Automatically retry a request on failure

## Perform multiple requests

- [`req_perform_iterative()`](https://httr2.r-lib.org/dev/reference/req_perform_iterative.md)
  : Perform requests iteratively, generating new requests from previous
  responses
- [`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md)
  : Perform a list of requests in parallel
- [`req_perform_sequential()`](https://httr2.r-lib.org/dev/reference/req_perform_sequential.md)
  : Perform multiple requests in sequence
- [`iterate_with_offset()`](https://httr2.r-lib.org/dev/reference/iterate_with_offset.md)
  [`iterate_with_cursor()`](https://httr2.r-lib.org/dev/reference/iterate_with_offset.md)
  [`iterate_with_link_url()`](https://httr2.r-lib.org/dev/reference/iterate_with_offset.md)
  : Iteration helpers
- [`resps_successes()`](https://httr2.r-lib.org/dev/reference/resps_successes.md)
  [`resps_failures()`](https://httr2.r-lib.org/dev/reference/resps_successes.md)
  [`resps_requests()`](https://httr2.r-lib.org/dev/reference/resps_successes.md)
  [`resps_data()`](https://httr2.r-lib.org/dev/reference/resps_successes.md)
  : Tools for working with lists of responses

## Handle the response

- [`resp_body_raw()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md)
  [`resp_has_body()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md)
  [`resp_body_string()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md)
  [`resp_body_json()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md)
  [`resp_body_html()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md)
  [`resp_body_xml()`](https://httr2.r-lib.org/dev/reference/resp_body_raw.md)
  : Extract body from response
- [`resp_check_content_type()`](https://httr2.r-lib.org/dev/reference/resp_check_content_type.md)
  : Check the content type of a response
- [`resp_content_type()`](https://httr2.r-lib.org/dev/reference/resp_content_type.md)
  [`resp_encoding()`](https://httr2.r-lib.org/dev/reference/resp_content_type.md)
  : Extract response content type and encoding
- [`resp_date()`](https://httr2.r-lib.org/dev/reference/resp_date.md) :
  Extract request date from response
- [`resp_headers()`](https://httr2.r-lib.org/dev/reference/resp_headers.md)
  [`resp_header()`](https://httr2.r-lib.org/dev/reference/resp_headers.md)
  [`resp_header_exists()`](https://httr2.r-lib.org/dev/reference/resp_headers.md)
  : Extract headers from a response
- [`resp_link_url()`](https://httr2.r-lib.org/dev/reference/resp_link_url.md)
  : Parse link URL from a response
- [`resp_raw()`](https://httr2.r-lib.org/dev/reference/resp_raw.md) :
  Show the raw response
- [`resp_request()`](https://httr2.r-lib.org/dev/reference/resp_request.md)
  : Find the request responsible for a response
- [`resp_retry_after()`](https://httr2.r-lib.org/dev/reference/resp_retry_after.md)
  : Extract wait time from a response
- [`resp_status()`](https://httr2.r-lib.org/dev/reference/resp_status.md)
  [`resp_status_desc()`](https://httr2.r-lib.org/dev/reference/resp_status.md)
  [`resp_is_error()`](https://httr2.r-lib.org/dev/reference/resp_status.md)
  [`resp_check_status()`](https://httr2.r-lib.org/dev/reference/resp_status.md)
  : Extract HTTP status from response
- [`resp_stream_raw()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md)
  [`resp_stream_lines()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md)
  [`resp_stream_sse()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md)
  [`resp_stream_aws()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md)
  [`close(`*`<httr2_response>`*`)`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md)
  [`resp_stream_is_complete()`](https://httr2.r-lib.org/dev/reference/resp_stream_raw.md)
  : Read a streaming body a chunk at a time
- [`resp_timing()`](https://httr2.r-lib.org/dev/reference/resp_timing.md)
  : Extract timing data
- [`resp_url()`](https://httr2.r-lib.org/dev/reference/resp_url.md)
  [`resp_url_path()`](https://httr2.r-lib.org/dev/reference/resp_url.md)
  [`resp_url_query()`](https://httr2.r-lib.org/dev/reference/resp_url.md)
  [`resp_url_queries()`](https://httr2.r-lib.org/dev/reference/resp_url.md)
  : Get URL/components from the response

## URL manipulation

- [`url_build()`](https://httr2.r-lib.org/dev/reference/url_build.md) :
  Build a string from a URL object
- [`url_modify()`](https://httr2.r-lib.org/dev/reference/url_modify.md)
  [`url_modify_relative()`](https://httr2.r-lib.org/dev/reference/url_modify.md)
  [`url_modify_query()`](https://httr2.r-lib.org/dev/reference/url_modify.md)
  : Modify a URL
- [`url_parse()`](https://httr2.r-lib.org/dev/reference/url_parse.md) :
  Parse a URL into its component pieces
- [`url_query_parse()`](https://httr2.r-lib.org/dev/reference/url_query_parse.md)
  [`url_query_build()`](https://httr2.r-lib.org/dev/reference/url_query_parse.md)
  : Parse query parameters and/or build a string

## Miscellaneous helpers

- [`curl_translate()`](https://httr2.r-lib.org/dev/reference/curl_translate.md)
  [`curl_help()`](https://httr2.r-lib.org/dev/reference/curl_translate.md)
  : Translate curl syntax to httr2
- [`is_online()`](https://httr2.r-lib.org/dev/reference/is_online.md) :
  Is your computer currently online?

## OAuth

These functions implement the low-level components of OAuth.

- [`oauth_cache_clear()`](https://httr2.r-lib.org/dev/reference/oauth_cache_clear.md)
  : Clear OAuth cache
- [`oauth_cache_path()`](https://httr2.r-lib.org/dev/reference/oauth_cache_path.md)
  : httr2 OAuth cache location
- [`oauth_client()`](https://httr2.r-lib.org/dev/reference/oauth_client.md)
  : Create an OAuth client
- [`oauth_client_req_auth()`](https://httr2.r-lib.org/dev/reference/oauth_client_req_auth.md)
  [`oauth_client_req_auth_header()`](https://httr2.r-lib.org/dev/reference/oauth_client_req_auth.md)
  [`oauth_client_req_auth_body()`](https://httr2.r-lib.org/dev/reference/oauth_client_req_auth.md)
  [`oauth_client_req_auth_jwt_sig()`](https://httr2.r-lib.org/dev/reference/oauth_client_req_auth.md)
  : OAuth client authentication
- [`oauth_redirect_uri()`](https://httr2.r-lib.org/dev/reference/oauth_redirect_uri.md)
  : Default redirect url for OAuth
- [`oauth_token()`](https://httr2.r-lib.org/dev/reference/oauth_token.md)
  : Create an OAuth token

## Developer tooling

These functions are useful when developing packges that use httr2.

### Keeping secrets

- [`obfuscate()`](https://httr2.r-lib.org/dev/reference/obfuscate.md)
  [`obfuscated()`](https://httr2.r-lib.org/dev/reference/obfuscate.md) :
  Obfuscate mildly secret information
- [`secret_make_key()`](https://httr2.r-lib.org/dev/reference/secrets.md)
  [`secret_encrypt()`](https://httr2.r-lib.org/dev/reference/secrets.md)
  [`secret_decrypt()`](https://httr2.r-lib.org/dev/reference/secrets.md)
  [`secret_write_rds()`](https://httr2.r-lib.org/dev/reference/secrets.md)
  [`secret_read_rds()`](https://httr2.r-lib.org/dev/reference/secrets.md)
  [`secret_decrypt_file()`](https://httr2.r-lib.org/dev/reference/secrets.md)
  [`secret_encrypt_file()`](https://httr2.r-lib.org/dev/reference/secrets.md)
  [`secret_has_key()`](https://httr2.r-lib.org/dev/reference/secrets.md)
  : Secret management

### Testing

- [`response()`](https://httr2.r-lib.org/dev/reference/response.md)
  [`response_json()`](https://httr2.r-lib.org/dev/reference/response.md)
  : Create a HTTP response for testing

### Introspection and mocking

- [`new_response()`](https://httr2.r-lib.org/dev/reference/new_response.md)
  : Create a HTTP response

- [`req_get_body_type()`](https://httr2.r-lib.org/dev/reference/req_get_body_type.md)
  [`req_get_body()`](https://httr2.r-lib.org/dev/reference/req_get_body_type.md)
  : Get request body

- [`req_get_headers()`](https://httr2.r-lib.org/dev/reference/req_get_headers.md)
  : Get request headers

- [`req_get_method()`](https://httr2.r-lib.org/dev/reference/req_get_method.md)
  : Get request method

- [`req_get_url()`](https://httr2.r-lib.org/dev/reference/req_get_url.md)
  : Get request URL

- [`StreamingBody`](https://httr2.r-lib.org/dev/reference/StreamingBody.md)
  :

  `StreamingBody` class

- [`with_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)
  [`local_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)
  : Temporarily mock requests
