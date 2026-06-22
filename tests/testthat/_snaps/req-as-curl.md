# req_as_curl() works with basic GET requests

    Code
      req_as_curl(request("https://hb.cran.dev/get"))
    Output
      curl https://hb.cran.dev/get \
        --location

# req_as_curl() works with POST methods

    Code
      req_as_curl(req_method(request("https://hb.cran.dev/post"), "POST"))
    Output
      curl https://hb.cran.dev/post \
        --request POST \
        --location

# req_as_curl() works with headers

    Code
      req_as_curl(req_headers(request("https://hb.cran.dev/get"), Accept = "application/json",
      `User-Agent` = "httr2/1.0"))
    Output
      curl https://hb.cran.dev/get \
        --header "Accept: application/json" \
        --header "User-Agent: httr2/1.0" \
        --location

# req_as_curl() works with JSON bodies

    Code
      req_as_curl(req_body_json(request("https://hb.cran.dev/post"), list(name = "test",
        value = 123)))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --header "Content-Type: application/json" \
        --data '{"name":"test","value":123}'

# req_as_curl() works with form bodies

    Code
      req_as_curl(req_body_form(request("https://hb.cran.dev/post"), name = "test",
      value = "123"))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --header "Content-Type: application/x-www-form-urlencoded" \
        --data "name=test&value=123"

# req_as_curl() works with multipart bodies

    Code
      req_as_curl(req_body_multipart(request("https://hb.cran.dev/post"), name = "test",
      value = "123"))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --form name=test \
        --form value=123

# req_as_curl() works with string bodies

    Code
      req_as_curl(req_body_raw(request("https://hb.cran.dev/post"), "test data",
      type = "text/plain"))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --header "Content-Type: text/plain" \
        --data "test data"

# req_as_curl() works with file bodies

    Code
      req_as_curl(req_body_file(request("https://hb.cran.dev/post"), path, type = "text/plain"))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --header "Content-Type: text/plain" \
        --data-binary @<tempfile>

# req_as_curl() works with custom content types

    Code
      req_as_curl(req_body_json(request("https://hb.cran.dev/post"), list(test = "data"),
      type = "application/vnd.api+json"))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --header "Content-Type: application/vnd.api+json" \
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
        --verbose

# req_as_curl() works with cookies

    Code
      req_as_curl(req_options(request("https://hb.cran.dev/cookies"), cookiejar = cookie_file,
      cookiefile = cookie_file))
    Output
      curl https://hb.cran.dev/cookies \
        --location \
        --cookie-jar <cookie-file> \
        --cookie <cookie-file>

# req_as_curl() works with obfuscated values in headers

    Code
      req_as_curl(req_headers(request("https://hb.cran.dev/get"), Authorization = obfuscated(
        "ZdYJeG8zwISodg0nu4UxBhs")))
    Output
      curl https://hb.cran.dev/get \
        --header "Authorization: <REDACTED>" \
        --location

# req_as_curl() can reveal obfuscated values

    Code
      req_as_curl(req_headers_redacted(request("https://hb.cran.dev/get"),
      Authorization = "secret-token"), obfuscated = "reveal")
    Output
      curl https://hb.cran.dev/get \
        --header "Authorization: secret-token" \
        --location

# req_as_curl() works with obfuscated values in JSON body

    Code
      req_as_curl(req_body_json(request("https://hb.cran.dev/post"), list(username = "test",
        password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"))))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --header "Content-Type: application/json" \
        --data '{"username":"test","password":"<REDACTED>"}'

# req_as_curl() works with obfuscated values in form body

    Code
      req_as_curl(req_body_form(request("https://hb.cran.dev/post"), username = "test",
      password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --header "Content-Type: application/x-www-form-urlencoded" \
        --data "username=test&password=<REDACTED>"

# req_as_curl() works with complex requests

    Code
      req_as_curl(req_body_json(req_headers(req_method(request(
        "https://api.github.com/user/repos"), "POST"), Accept = "application/vnd.github.v3+json",
      Authorization = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"), `User-Agent` = "MyApp/1.0"),
      list(name = "test-repo", description = "A test repository", private = TRUE)))
    Output
      curl https://api.github.com/user/repos \
        --header "Accept: application/vnd.github.v3+json" \
        --header "Authorization: <REDACTED>" \
        --header "User-Agent: MyApp/1.0" \
        --location \
        --header "Content-Type: application/json" \
        --data '{"name":"test-repo","description":"A test repository","private":true}'

# req_as_curl() puts a request with no arguments on a single line

    Code
      req_as_curl(req_options(request("https://hb.cran.dev/get"), followlocation = FALSE))
    Output
      curl https://hb.cran.dev/get

# req_as_curl() validates input

    Code
      req_as_curl("not a request")
    Condition
      Error in `req_as_curl()`:
      ! `req` must be an HTTP request object, not the string "not a request".

# req_as_curl() encodes raw bodies as binary

    Code
      req_as_curl(req_body_raw(request("https://hb.cran.dev/post"), as.raw(c(0, 104,
        105, 255)), type = "application/octet-stream"))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --header "Content-Type: application/octet-stream" \
        --data-raw $'\x00hi\xff'

# an explicit Content-Type header isn't duplicated by the body

    Code
      req_as_curl(req_body_raw(req_headers(request("https://hb.cran.dev/post"),
      `Content-Type` = "application/json"), "{}"))
    Output
      curl https://hb.cran.dev/post \
        --header "Content-Type: application/json" \
        --location \
        --data "{}"

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

