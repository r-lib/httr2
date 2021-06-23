# can print all url details

    Code
      url_parse("http://user:pass@example.com:80/path?a=1&b=2#frag")
    Message <cliMessage>
      <httr2_url> http://user:pass@example.com:80/path?a=1&b=2#frag
      * scheme: http
      * hostname: example.com
      * username: user
      * password: pass
      * port: 80
      * path: /path
      * query:
        ( ) a: 1
        ( ) b: 2
      * fragment: frag

