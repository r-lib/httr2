# can print all url details

    Code
      url_parse("http://user:pass@example.com:80/path?a=1&b=2&c={1{2}3}#frag")
    Message
      <httr2_url> http://user:pass@example.com:80/path?a=1&b=2&c=%7B1%7B2%7D3%7D#frag
      * scheme: http
      * hostname: example.com
      * username: user
      * password: pass
      * port: 80
      * path: /path
      * query:
        * a: 1
        * b: 2
        * c: {1{2}3}
      * fragment: frag

# password also requires username

    Code
      url_build(url)
    Condition
      Error in `url_build()`:
      ! Cannot set url `password` without `username`.

# url_modify checks its inputs

    Code
      url_modify(1)
    Condition
      Error in `url_modify()`:
      ! `url` must be a string or parsed URL, not the number 1.
    Code
      url_modify(url, scheme = 1)
    Condition
      Error in `url_modify()`:
      ! `scheme` must be a single string or `NULL`, not the number 1.
    Code
      url_modify(url, hostname = 1)
    Condition
      Error in `url_modify()`:
      ! `hostname` must be a single string or `NULL`, not the number 1.
    Code
      url_modify(url, port = "x")
    Condition
      Error in `url_modify()`:
      ! `port` must be a whole number or `NULL`, not the string "x".
    Code
      url_modify(url, username = 1)
    Condition
      Error in `url_modify()`:
      ! `username` must be a single string or `NULL`, not the number 1.
    Code
      url_modify(url, password = 1)
    Condition
      Error in `url_modify()`:
      ! `password` must be a single string or `NULL`, not the number 1.
    Code
      url_modify(url, path = 1)
    Condition
      Error in `url_modify()`:
      ! `path` must be a single string or `NULL`, not the number 1.
    Code
      url_modify(url, fragment = 1)
    Condition
      Error in `url_modify()`:
      ! `fragment` must be a single string or `NULL`, not the number 1.

# checks various query formats

    Code
      url_modify(url, query = 1)
    Condition
      Error in `url_modify()`:
      ! `query` must be a character vector, named list, or NULL, not the number 1.
    Code
      url_modify(url, query = list(1))
    Condition
      Error in `url_modify()`:
      ! `query` must be a character vector, named list, or NULL, not a list.
    Code
      url_modify(url, query = list(x = 1:2))
    Condition
      Error in `url_modify()`:
      ! Query value `query$x` must be a length-1 atomic vector, not an integer vector.

# validates inputs

    Code
      query_build(1:3)
    Condition
      Error:
      ! Query must be a named list.
    Code
      query_build(list(x = 1:2, y = 1:3))
    Condition
      Error:
      ! Query value `x` must be a length-1 atomic vector, not an integer vector.

# can't opt out of escaping non strings

    Code
      format_query_param(I(1), "x")
    Condition
      Error:
      ! Escaped query value `x` must be a single string, not the number 1.

