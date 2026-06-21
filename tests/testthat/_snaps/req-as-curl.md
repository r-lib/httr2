# req_as_curl() works with basic GET requests

    Code
      req_as_curl(request("https://hb.cran.dev/get"))
    Output
      curl https://hb.cran.dev/get

# req_as_curl() works with POST methods

    Code
      req_as_curl(req_method(request("https://hb.cran.dev/post"), "POST"))
    Output
      curl https://hb.cran.dev/post \
        -X POST

# req_as_curl() works with headers

    Code
      req_as_curl(req_headers(request("https://hb.cran.dev/get"), Accept = "application/json",
      `User-Agent` = "httr2/1.0"))
    Output
      curl https://hb.cran.dev/get \
        -H "Accept: application/json" \
        -H "User-Agent: httr2/1.0"

# req_as_curl() works with JSON bodies

    Code
      req_as_curl(req_body_json(request("https://hb.cran.dev/post"), list(name = "test",
        value = 123)))
    Output
      curl https://hb.cran.dev/post \
        -H "Content-Type: application/json" \
        -d '{"name":"test","value":123}'

# req_as_curl() works with form bodies

    Code
      req_as_curl(req_body_form(request("https://hb.cran.dev/post"), name = "test",
      value = "123"))
    Output
      curl https://hb.cran.dev/post \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "name=test&value=123"

# req_as_curl() works with multipart bodies

    Code
      req_as_curl(req_body_multipart(request("https://hb.cran.dev/post"), name = "test",
      value = "123"))
    Output
      curl https://hb.cran.dev/post \
        -F name=test \
        -F value=123

# req_as_curl() works with string bodies

    Code
      req_as_curl(req_body_raw(request("https://hb.cran.dev/post"), "test data",
      type = "text/plain"))
    Output
      curl https://hb.cran.dev/post \
        -H "Content-Type: text/plain" \
        -d "test data"

# req_as_curl() works with file bodies

    Code
      req_as_curl(req_body_file(request("https://hb.cran.dev/post"), path, type = "text/plain"))
    Output
      curl https://hb.cran.dev/post \
        -H "Content-Type: text/plain" \
        --data-binary @<tempfile>

# req_as_curl() works with custom content types

    Code
      req_as_curl(req_body_json(request("https://hb.cran.dev/post"), list(test = "data"),
      type = "application/vnd.api+json"))
    Output
      curl https://hb.cran.dev/post \
        -H "Content-Type: application/vnd.api+json" \
        -d '{"test":"data"}'

# req_as_curl() works with options

    Code
      req_as_curl(req_options(request("https://hb.cran.dev/get"), timeout = 30,
      verbose = TRUE, ssl_verifypeer = FALSE))
    Condition
      Warning:
      Can't translate option "ssl_verifypeer".
    Output
      curl https://hb.cran.dev/get \
        --max-time 30 \
        --verbose

# req_as_curl() works with cookies

    Code
      req_as_curl(req_options(request("https://hb.cran.dev/cookies"), cookiejar = cookie_file,
      cookiefile = cookie_file))
    Output
      curl https://hb.cran.dev/cookies \
        --cookie-jar <cookie-file> \
        --cookie <cookie-file>

# req_as_curl() works with obfuscated values in headers

    Code
      req_as_curl(req_headers(request("https://hb.cran.dev/get"), Authorization = obfuscated(
        "ZdYJeG8zwISodg0nu4UxBhs")))
    Output
      curl https://hb.cran.dev/get \
        -H "Authorization: <REDACTED>"

# req_as_curl() can reveal obfuscated values

    Code
      req_as_curl(req_headers_redacted(request("https://hb.cran.dev/get"),
      Authorization = "secret-token"), obfuscated = "reveal")
    Output
      curl https://hb.cran.dev/get \
        -H "Authorization: secret-token"

# req_as_curl() works with obfuscated values in JSON body

    Code
      req_as_curl(req_body_json(request("https://hb.cran.dev/post"), list(username = "test",
        password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"))))
    Output
      curl https://hb.cran.dev/post \
        -H "Content-Type: application/json" \
        -d '{"username":"test","password":"<REDACTED>"}'

# req_as_curl() works with obfuscated values in form body

    Code
      req_as_curl(req_body_form(request("https://hb.cran.dev/post"), username = "test",
      password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")))
    Output
      curl https://hb.cran.dev/post \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=test&password=<REDACTED>"

# req_as_curl() works with complex requests

    Code
      req_as_curl(req_options(req_body_json(req_headers(req_method(request(
        "https://api.github.com/user/repos"), "POST"), Accept = "application/vnd.github.v3+json",
      Authorization = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"), `User-Agent` = "MyApp/1.0"),
      list(name = "test-repo", description = "A test repository", private = TRUE)),
      timeout = 60))
    Output
      curl https://api.github.com/user/repos \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: <REDACTED>" \
        -H "User-Agent: MyApp/1.0" \
        --max-time 60 \
        -H "Content-Type: application/json" \
        -d '{"name":"test-repo","description":"A test repository","private":true}'

# req_as_curl() works with simple requests (single line)

    Code
      req_as_curl(request("https://hb.cran.dev/get"))
    Output
      curl https://hb.cran.dev/get

# req_as_curl() validates input

    Code
      req_as_curl("not a request")
    Condition
      Error in `req_as_curl()`:
      ! `req` must be an HTTP request object, not the string "not a request".

# req_as_curl() reads raw bodies from stdin

    Code
      req_as_curl(req_body_raw(request("https://hb.cran.dev/post"), charToRaw(
        "test data"), type = "text/plain"))
    Output
      curl https://hb.cran.dev/post \
        -H "Content-Type: text/plain" \
        --data-binary @-

# an explicit Content-Type header isn't duplicated by the body

    Code
      req_as_curl(req_body_raw(req_headers(request("https://hb.cran.dev/post"),
      `Content-Type` = "application/json"), "{}"))
    Output
      curl https://hb.cran.dev/post \
        -H "Content-Type: application/json" \
        -d "{}"

# req_options_as_curl() translates each known option

    Code
      cat(req_options_as_curl(req), sep = "\n")
    Output
      --max-time 30
      --connect-timeout 5
      --proxy http://proxy.example.com
      --user-agent agent
      --referer http://referer.example.com
      --location
      --verbose
      --cookie-jar jar.txt
      --cookie file.txt

# req_options_as_curl() warns about untranslatable options

    Code
      out <- req_options_as_curl(req)
    Condition
      Warning:
      Can't translate option "ssl_verifypeer".

