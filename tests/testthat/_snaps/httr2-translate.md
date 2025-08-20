# httr2_translate() works with basic GET requests

    Code
      httr2_translate(request("https://httpbin.org/get"))
    Output
      [1] "curl \"https://httpbin.org/get\""

# httr2_translate() works with POST methods

    Code
      httr2_translate(req_method(request("https://httpbin.org/post"), "POST"))
    Output
      [1] "curl -X POST \\\n  \"https://httpbin.org/post\""

# httr2_translate() works with headers

    Code
      httr2_translate(req_headers(request("https://httpbin.org/get"), Accept = "application/json",
      `User-Agent` = "httr2/1.0"))
    Output
      [1] "curl -H \"Accept: application/json\" \\\n  -H \"User-Agent: httr2/1.0\" \\\n  \"https://httpbin.org/get\""

# httr2_translate() works with JSON bodies

    Code
      httr2_translate(req_body_json(request("https://httpbin.org/post"), list(name = "test",
        value = 123)))
    Output
      [1] "curl -X POST \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\"name\":\"test\",\"value\":123}' \\\n  \"https://httpbin.org/post\""

# httr2_translate() works with form bodies

    Code
      httr2_translate(req_body_form(request("https://httpbin.org/post"), name = "test",
      value = "123"))
    Output
      [1] "curl -X POST \\\n  -H \"Content-Type: application/x-www-form-urlencoded\" \\\n  -d \"name=test&value=123\" \\\n  \"https://httpbin.org/post\""

# httr2_translate() works with multipart bodies

    Code
      httr2_translate(req_body_multipart(request("https://httpbin.org/post"), name = "test",
      value = "123"))
    Output
      [1] "curl -X POST \\\n  -F \"name=test\" \\\n  -F \"value=123\" \\\n  \"https://httpbin.org/post\""

# httr2_translate() works with string bodies

    Code
      httr2_translate(req_body_raw(request("https://httpbin.org/post"), "test data",
      type = "text/plain"))
    Output
      [1] "curl -X POST \\\n  -H \"Content-Type: text/plain\" \\\n  -d \"test data\" \\\n  \"https://httpbin.org/post\""

# httr2_translate() works with file bodies

    Code
      httr2_translate(req_body_file(request("https://httpbin.org/post"), path, type = "text/plain"))
    Output
      [1] "curl -X POST \\\n  -H \"Content-Type: text/plain\" \\\n  --data-binary \"@<tempfile>\" \\\n  \"https://httpbin.org/post\""

# httr2_translate() works with custom content types

    Code
      httr2_translate(req_body_json(request("https://httpbin.org/post"), list(test = "data"),
      type = "application/vnd.api+json"))
    Output
      [1] "curl -X POST \\\n  -H \"Content-Type: application/vnd.api+json\" \\\n  -d '{\"test\":\"data\"}' \\\n  \"https://httpbin.org/post\""

# httr2_translate() works with options

    Code
      httr2_translate(req_options(request("https://httpbin.org/get"), timeout = 30,
      verbose = TRUE, ssl_verifypeer = FALSE))
    Output
      [1] "curl --max-time 30 \\\n  --verbose \\\n  --insecure \\\n  \"https://httpbin.org/get\""

# httr2_translate() works with cookies

    Code
      httr2_translate(req_options(request("https://httpbin.org/cookies"), cookiejar = cookie_file,
      cookiefile = cookie_file))
    Output
      [1] "curl --cookie-jar \"<cookie-file>\" \\\n  --cookie \"<cookie-file>\" \\\n  \"https://httpbin.org/cookies\""

# httr2_translate() works with obfuscated values in headers

    Code
      httr2_translate(req_headers(request("https://httpbin.org/get"), Authorization = obfuscated(
        "ZdYJeG8zwISodg0nu4UxBhs")))
    Output
      [1] "curl -H \"Authorization: y\" \\\n  \"https://httpbin.org/get\""

# httr2_translate() works with obfuscated values in JSON body

    Code
      httr2_translate(req_body_json(request("https://httpbin.org/post"), list(
        username = "test", password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"))))
    Output
      [1] "curl -X POST \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\"username\":\"test\",\"password\":\"y\"}' \\\n  \"https://httpbin.org/post\""

# httr2_translate() works with obfuscated values in form body

    Code
      httr2_translate(req_body_form(request("https://httpbin.org/post"), username = "test",
      password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")))
    Output
      [1] "curl -X POST \\\n  -H \"Content-Type: application/x-www-form-urlencoded\" \\\n  -d \"username=test&password=y\" \\\n  \"https://httpbin.org/post\""

# httr2_translate() works with complex requests

    Code
      httr2_translate(req_options(req_body_json(req_headers(req_method(request(
        "https://api.github.com/user/repos"), "POST"), Accept = "application/vnd.github.v3+json",
      Authorization = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"), `User-Agent` = "MyApp/1.0"),
      list(name = "test-repo", description = "A test repository", private = TRUE)),
      timeout = 60))
    Output
      [1] "curl -X POST \\\n  -H \"Accept: application/vnd.github.v3+json\" \\\n  -H \"Authorization: y\" \\\n  -H \"User-Agent: MyApp/1.0\" \\\n  --max-time 60 \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\"name\":\"test-repo\",\"description\":\"A test repository\",\"private\":true}' \\\n  \"https://api.github.com/user/repos\""

# httr2_translate() works with simple requests (single line)

    Code
      httr2_translate(request("https://httpbin.org/get"))
    Output
      [1] "curl \"https://httpbin.org/get\""

# httr2_translate() validates input

    Code
      httr2_translate("not a request")
    Condition
      Error in `httr2_translate()`:
      ! `.req` must be an HTTP request object, not the string "not a request".

