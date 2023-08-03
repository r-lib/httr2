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

