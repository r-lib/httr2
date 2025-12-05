# Show the raw response

This function reconstructs the HTTP message that httr2 received from the
server. It's unlikely to be exactly byte-for-byte identical (because
most servers compress at least the body, and HTTP/2 can also compress
the headers), but it conveys the same information.

## Usage

``` r
resp_raw(resp)
```

## Arguments

- resp:

  A httr2 [response](https://httr2.r-lib.org/dev/reference/response.md)
  object, created by
  [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md).

## Value

`resp` (invisibly).

## Examples

``` r
resp <- request(example_url()) |>
  req_url_path("/json") |>
  req_perform()
resp |> resp_raw()
#> HTTP/1.1 200 OK
#> Date: Fri, 05 Dec 2025 14:12:12 GMT
#> Content-Type: application/json
#> Content-Length: 407
#> ETag: "de760e6d"
#> 
#> {
#>   "firstName": "John",
#>   "lastName": "Smith",
#>   "isAlive": true,
#>   "age": 27,
#>   "address": {
#>     "streetAddress": "21 2nd Street",
#>     "city": "New York",
#>     "state": "NY",
#>     "postalCode": "10021-3100"
#>   },
#>   "phoneNumbers": [
#>     {
#>       "type": "home",
#>       "number": "212 555-1234"
#>     },
#>     {
#>       "type": "office",
#>       "number": "646 555-4567"
#>     }
#>   ],
#>   "children": [],
#>   "spouse": null
#> }
#> 
```
