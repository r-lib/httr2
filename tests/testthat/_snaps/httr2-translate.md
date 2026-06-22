# httr2_translate() works with basic GET requests

    Code
      httr2_translate(request("https://hb.cran.dev/get"))
    Output
      curl https://hb.cran.dev/get \
        --location \
        --user-agent httr2

# httr2_translate() works with POST methods

    Code
      httr2_translate(req_method(request("https://hb.cran.dev/post"), "POST"))
    Output
      curl https://hb.cran.dev/post \
        --request POST \
        --location \
        --user-agent httr2

# httr2_translate() works with headers

    Code
      httr2_translate(req_headers(request("https://hb.cran.dev/get"), Accept = "application/json",
      `User-Agent` = "httr2/1.0"))
    Output
      curl https://hb.cran.dev/get \
        --header 'Accept: application/json' \
        --header 'User-Agent: httr2/1.0' \
        --location \
        --user-agent httr2

# httr2_translate() works with JSON bodies

    Code
      httr2_translate(req_body_json(request("https://hb.cran.dev/post"), list(name = "test",
        value = 123)))
    Output
      curl https://hb.cran.dev/post \
        --header 'Content-Type: application/json' \
        --location \
        --user-agent httr2 \
        --data '{"name":"test","value":123}'

# httr2_translate() works with form bodies

    Code
      httr2_translate(req_body_form(request("https://hb.cran.dev/post"), name = "test",
      value = "123"))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --user-agent httr2 \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --data 'name=test&value=123'

# httr2_translate() works with multipart bodies

    Code
      httr2_translate(req_body_multipart(request("https://hb.cran.dev/post"), name = "test",
      value = "123"))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --user-agent httr2 \
        --form-string name=test \
        --form-string value=123

# httr2_translate() works with string bodies

    Code
      httr2_translate(req_body_raw(request("https://hb.cran.dev/post"), "test data",
      type = "text/plain"))
    Output
      curl https://hb.cran.dev/post \
        --header 'Content-Type: text/plain' \
        --location \
        --user-agent httr2 \
        --data 'test data'

# httr2_translate() works with file bodies

    Code
      httr2_translate(req_body_file(request("https://hb.cran.dev/post"), path, type = "text/plain"))
    Output
      curl https://hb.cran.dev/post \
        --header 'Content-Type: text/plain' \
        --location \
        --user-agent httr2 \
        --data-binary @<tempfile>

# httr2_translate() works with custom content types

    Code
      httr2_translate(req_body_json(request("https://hb.cran.dev/post"), list(test = "data"),
      type = "application/vnd.api+json"))
    Output
      curl https://hb.cran.dev/post \
        --header 'Content-Type: application/vnd.api+json' \
        --location \
        --user-agent httr2 \
        --data '{"test":"data"}'

# httr2_translate() works with options

    Code
      httr2_translate(req_options(request("https://hb.cran.dev/get"), verbose = TRUE,
      ssl_verifypeer = FALSE))
    Condition
      Warning:
      Can't translate option "ssl_verifypeer".
    Output
      curl https://hb.cran.dev/get \
        --location \
        --verbose \
        --user-agent httr2

# httr2_translate() works with cookies

    Code
      httr2_translate(req_options(request("https://hb.cran.dev/cookies"), cookiejar = cookie_file,
      cookiefile = cookie_file))
    Output
      curl https://hb.cran.dev/cookies \
        --location \
        --cookie-jar <cookie-file> \
        --cookie <cookie-file> \
        --user-agent httr2

# httr2_translate() works with obfuscated values in headers

    Code
      httr2_translate(req_headers(request("https://hb.cran.dev/get"), Authorization = obfuscated(
        "ZdYJeG8zwISodg0nu4UxBhs")))
    Output
      curl https://hb.cran.dev/get \
        --header 'Authorization: <REDACTED>' \
        --location \
        --user-agent httr2

# httr2_translate() can reveal obfuscated values

    Code
      httr2_translate(req_headers_redacted(request("https://hb.cran.dev/get"),
      Authorization = "secret-token"), obfuscated = "reveal")
    Output
      curl https://hb.cran.dev/get \
        --header 'Authorization: secret-token' \
        --location \
        --user-agent httr2

# httr2_translate() works with obfuscated values in JSON body

    Code
      httr2_translate(req_body_json(request("https://hb.cran.dev/post"), list(
        username = "test", password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"))))
    Output
      curl https://hb.cran.dev/post \
        --header 'Content-Type: application/json' \
        --location \
        --user-agent httr2 \
        --data '{"username":"test","password":"<REDACTED>"}'

# httr2_translate() works with obfuscated values in form body

    Code
      httr2_translate(req_body_form(request("https://hb.cran.dev/post"), username = "test",
      password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")))
    Output
      curl https://hb.cran.dev/post \
        --location \
        --user-agent httr2 \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --data 'username=test&password=%3CREDACTED%3E'

# httr2_translate() works with complex requests

    Code
      httr2_translate(req_body_json(req_headers(req_method(request(
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

# httr2_translate() puts a request with no arguments on a single line

    Code
      httr2_translate(req_options(request("https://hb.cran.dev/get"), followlocation = FALSE))
    Output
      curl https://hb.cran.dev/get \
        --user-agent httr2

# httr2_translate() validates input

    Code
      httr2_translate("not a request")
    Condition
      Error in `httr2_translate()`:
      ! `req` must be an HTTP request object, not the string "not a request".

# httr2_translate() errors for raw bodies

    Code
      httr2_translate(req)
    Condition
      Error:
      ! Can't translate a request with a raw body.

# an explicit Content-Type header isn't duplicated by the body

    Code
      httr2_translate(req_body_raw(req_headers(request("https://hb.cran.dev/post"),
      `Content-Type` = "application/json"), "{}"))
    Output
      curl https://hb.cran.dev/post \
        --header 'Content-Type: application/json' \
        --location \
        --user-agent httr2 \
        --data '{}'

# curl_body_data() translates multipart values

    Code
      writeLines(curl_body_data(body, "multipart"))
    Output
      --form-string 'text=@literal;value'
      --form 'file=@"<tmppath>";type=text/plain;filename="name.txt"'
      --form 'data="a b";type=text/plain'

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

