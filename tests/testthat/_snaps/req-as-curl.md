# req_as_curl() works with basic GET requests

    Code
      req_as_curl(request("https://hb.cran.dev/get"))
    Output
      curl "https://hb.cran.dev/get"

# req_as_curl() works with POST methods

    Code
      req_as_curl(req_method(request("https://hb.cran.dev/post"), "POST"))
    Output
      curl -X POST \
        "https://hb.cran.dev/post"

# req_as_curl() works with headers

    Code
      req_as_curl(req_headers(request("https://hb.cran.dev/get"), Accept = "application/json",
      `User-Agent` = "httr2/1.0"))
    Output
      curl -H "Accept: application/json" \
        -H "User-Agent: httr2/1.0" \
        "https://hb.cran.dev/get"

# req_as_curl() works with JSON bodies

    Code
      req_as_curl(req_body_json(request("https://hb.cran.dev/post"), list(name = "test",
        value = 123)))
    Output
      curl -X POST \
        -H "Content-Type: application/json" \
        -d '{"name":"test","value":123}' \
        "https://hb.cran.dev/post"

# req_as_curl() works with form bodies

    Code
      req_as_curl(req_body_form(request("https://hb.cran.dev/post"), name = "test",
      value = "123"))
    Output
      curl -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "name=test&value=123" \
        "https://hb.cran.dev/post"

# req_as_curl() works with multipart bodies

    Code
      req_as_curl(req_body_multipart(request("https://hb.cran.dev/post"), name = "test",
      value = "123"))
    Output
      curl -X POST \
        -F "name=test" \
        -F "value=123" \
        "https://hb.cran.dev/post"

# req_as_curl() works with string bodies

    Code
      req_as_curl(req_body_raw(request("https://hb.cran.dev/post"), "test data",
      type = "text/plain"))
    Output
      curl -X POST \
        -H "Content-Type: text/plain" \
        -d "test data" \
        "https://hb.cran.dev/post"

# req_as_curl() works with file bodies

    Code
      req_as_curl(req_body_file(request("https://hb.cran.dev/post"), path, type = "text/plain"))
    Output
      curl -X POST \
        -H "Content-Type: text/plain" \
        --data-binary "@<tempfile>" \
        "https://hb.cran.dev/post"

# req_as_curl() works with custom content types

    Code
      req_as_curl(req_body_json(request("https://hb.cran.dev/post"), list(test = "data"),
      type = "application/vnd.api+json"))
    Output
      curl -X POST \
        -H "Content-Type: application/vnd.api+json" \
        -d '{"test":"data"}' \
        "https://hb.cran.dev/post"

# req_as_curl() works with options

    Code
      req_as_curl(req_options(request("https://hb.cran.dev/get"), timeout = 30,
      verbose = TRUE, ssl_verifypeer = FALSE))
    Message
      ! Unable to translate option "ssl_verifypeer"
    Output
      curl --max-time 30 \
        --verbose \
        "https://hb.cran.dev/get"

# req_as_curl() works with cookies

    Code
      req_as_curl(req_options(request("https://hb.cran.dev/cookies"), cookiejar = cookie_file,
      cookiefile = cookie_file))
    Output
      curl --cookie-jar "<cookie-file>" \
        --cookie "<cookie-file>" \
        "https://hb.cran.dev/cookies"

# req_as_curl() works with obfuscated values in headers

    Code
      req_as_curl(req_headers(request("https://hb.cran.dev/get"), Authorization = obfuscated(
        "ZdYJeG8zwISodg0nu4UxBhs")))
    Output
      curl -H "Authorization: ZdYJeG8zwISodg0nu4UxBhs" \
        "https://hb.cran.dev/get"

# req_as_curl() works with obfuscated values in JSON body

    Code
      req_as_curl(req_body_json(request("https://hb.cran.dev/post"), list(username = "test",
        password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"))))
    Output
      curl -X POST \
        -H "Content-Type: application/json" \
        -d '{"username":"test","password":"y"}' \
        "https://hb.cran.dev/post"

# req_as_curl() works with obfuscated values in form body

    Code
      req_as_curl(req_body_form(request("https://hb.cran.dev/post"), username = "test",
      password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")))
    Output
      curl -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=test&password=y" \
        "https://hb.cran.dev/post"

# req_as_curl() works with complex requests

    Code
      req_as_curl(req_options(req_body_json(req_headers(req_method(request(
        "https://api.github.com/user/repos"), "POST"), Accept = "application/vnd.github.v3+json",
      Authorization = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"), `User-Agent` = "MyApp/1.0"),
      list(name = "test-repo", description = "A test repository", private = TRUE)),
      timeout = 60))
    Output
      curl -X POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: ZdYJeG8zwISodg0nu4UxBhs" \
        -H "User-Agent: MyApp/1.0" \
        --max-time 60 \
        -H "Content-Type: application/json" \
        -d '{"name":"test-repo","description":"A test repository","private":true}' \
        "https://api.github.com/user/repos"

# req_as_curl() works with simple requests (single line)

    Code
      req_as_curl(request("https://hb.cran.dev/get"))
    Output
      curl "https://hb.cran.dev/get"

# req_as_curl() validates input

    Code
      req_as_curl("not a request")
    Condition
      Error in `req_as_curl()`:
      ! `req` must be an HTTP request object, not the string "not a request".

