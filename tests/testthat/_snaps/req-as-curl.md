# req_as_curl() works with basic GET requests

    Code
      req_as_curl(request("https://hb.cran.dev/get"))
    Output
      curl https://hb.cran.dev/get \
        --location \
        --user-agent httr2

# req_as_curl() works with POST methods

    Code
      req_as_curl(req_method(request("https://hb.cran.dev/post"), "POST"))
    Output
      curl https://hb.cran.dev/post \
        --request POST \
        --location \
        --user-agent httr2

# req_as_curl() works with headers

    Code
      req_as_curl(req_headers(request("https://hb.cran.dev/get"), Accept = "application/json",
      `User-Agent` = "httr2/1.0"))
    Output
      curl https://hb.cran.dev/get \
        --header 'Accept: application/json' \
        --header 'User-Agent: httr2/1.0' \
        --location \
        --user-agent httr2

# req_as_curl() works with JSON bodies

    Code
      req_as_curl(req_body_json(request("https://hb.cran.dev/post"), list(name = "test",
        value = 123)))
    Output
      curl https://hb.cran.dev/post \
        --header 'Content-Type: application/json' \
        --location \
        --user-agent httr2 \
        --data '{"name":"test","value":123}'

# req_as_curl() works with form bodies

    Code
      req_as_curl(req_body_form(request("https://hb.cran.dev/post"), name = "test",
      value = "123"))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --user-agent httr2 \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --data 'name=test&value=123'

# req_as_curl() works with multipart bodies

    Code
      req_as_curl(req_body_multipart(request("https://hb.cran.dev/post"), name = "test",
      value = "123"))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --user-agent httr2 \
        --form-string name=test \
        --form-string value=123

# req_as_curl() works with string bodies

    Code
      req_as_curl(req_body_raw(request("https://hb.cran.dev/post"), "test data",
      type = "text/plain"))
    Output
      curl https://hb.cran.dev/post \
        --header 'Content-Type: text/plain' \
        --location \
        --user-agent httr2 \
        --data 'test data'

# req_as_curl() works with file bodies

    Code
      req_as_curl(req_body_file(request("https://hb.cran.dev/post"), path, type = "text/plain"))
    Output
      curl https://hb.cran.dev/post \
        --header 'Content-Type: text/plain' \
        --location \
        --user-agent httr2 \
        --data-binary @<tempfile>

# req_as_curl() works with custom content types

    Code
      req_as_curl(req_body_json(request("https://hb.cran.dev/post"), list(test = "data"),
      type = "application/vnd.api+json"))
    Output
      curl https://hb.cran.dev/post \
        --header 'Content-Type: application/vnd.api+json' \
        --location \
        --user-agent httr2 \
        --data '{"test":"data"}'

# req_as_curl() works with options

    Code
      req_as_curl(req_options(request("https://hb.cran.dev/get"), verbose = TRUE,
      ssl_verifypeer = FALSE))
    Condition
      Warning:
      Can't translate option "ssl_verifypeer".
    Output
      curl https://hb.cran.dev/get \
        --location \
        --verbose \
        --user-agent httr2

# req_as_curl() works with cookies

    Code
      req_as_curl(req_options(request("https://hb.cran.dev/cookies"), cookiejar = cookie_file,
      cookiefile = cookie_file))
    Output
      curl https://hb.cran.dev/cookies \
        --location \
        --cookie-jar <cookie-file> \
        --cookie <cookie-file> \
        --user-agent httr2

# req_as_curl() works with obfuscated values in headers

    Code
      req_as_curl(req_headers(request("https://hb.cran.dev/get"), Authorization = obfuscated(
        "ZdYJeG8zwISodg0nu4UxBhs")))
    Output
      curl https://hb.cran.dev/get \
        --header 'Authorization: <REDACTED>' \
        --location \
        --user-agent httr2

# req_as_curl() can reveal obfuscated values

    Code
      req_as_curl(req_headers_redacted(request("https://hb.cran.dev/get"),
      Authorization = "secret-token"), obfuscated = "reveal")
    Output
      curl https://hb.cran.dev/get \
        --header 'Authorization: secret-token' \
        --location \
        --user-agent httr2

# req_as_curl() works with obfuscated values in JSON body

    Code
      req_as_curl(req_body_json(request("https://hb.cran.dev/post"), list(username = "test",
        password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"))))
    Output
      curl https://hb.cran.dev/post \
        --header 'Content-Type: application/json' \
        --location \
        --user-agent httr2 \
        --data '{"username":"test","password":"<REDACTED>"}'

# req_as_curl() works with obfuscated values in form body

    Code
      req_as_curl(req_body_form(request("https://hb.cran.dev/post"), username = "test",
      password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --user-agent httr2 \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --data 'username=test&password=%3CREDACTED%3E'

# req_as_curl() works with complex requests

    Code
      req_as_curl(req_body_json(req_headers(req_method(request(
        "https://api.github.com/user/repos"), "POST"), Accept = "application/vnd.github.v3+json",
      Authorization = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"), `User-Agent` = "MyApp/1.0"),
      list(name = "test-repo", description = "A test repository", private = TRUE)))
    Output
      curl https://api.github.com/user/repos \
        --header 'Accept: application/vnd.github.v3+json' \
        --header 'Authorization: <REDACTED>' \
        --header 'User-Agent: MyApp/1.0' \
        --header 'Content-Type: application/json' \
        --location \
        --user-agent httr2 \
        --data '{"name":"test-repo","description":"A test repository","private":true}'

# req_as_curl() puts a request with no arguments on a single line

    Code
      req_as_curl(req_options(request("https://hb.cran.dev/get"), followlocation = FALSE))
    Output
      curl https://hb.cran.dev/get \
        --user-agent httr2

# req_as_curl() validates input

    Code
      req_as_curl("not a request")
    Condition
      Error in `req_as_curl()`:
      ! `req` must be an HTTP request object, not the string "not a request".

# req_as_curl() errors for raw bodies

    Code
      req_as_curl(req)
    Condition
      Error:
      ! Can't translate a request with a raw body.

# an explicit Content-Type header isn't duplicated by the body

    Code
      req_as_curl(req_body_raw(req_headers(request("https://hb.cran.dev/post"),
      `Content-Type` = "application/json"), "{}"))
    Output
      curl https://hb.cran.dev/post \
        --header 'Content-Type: application/json' \
        --location \
        --user-agent httr2 \
        --data '{}'

# curl_options() translates each known option

    Code
      cat(curl_options(req), sep = "\n")
    Output
      --location
      --max-time 30
      --connect-timeout 5
      --proxy http://proxy.example.com
      --user-agent agent
      --verbose
      --cookie-jar jar.txt
      --cookie file.txt

# curl_options() translates options set by httr2 functions

    Code
      cat(curl_options(req), sep = "\n")
    Output
      --location
      --max-time 30
      --connect-timeout 0
      --proxy proxy.example.com:8080
      --proxy-user u:p
      --user-agent agent
      --cookie-jar cookies.txt
      --cookie cookies.txt
      --cookie session=abc

# curl_options() warns about untranslatable options

    Code
      out <- curl_options(req)
    Condition
      Warning:
      Can't translate option "ssl_verifypeer".

