#' Extract information about the timing of the response
#'
#' The underlying curl library measures how long different components of the
#' request take to complete. This function retrieves that information.
#'
#' The names of the elements in this vector correspond to the enum used
#' in libcurl's `curl_easy_getinfo()` API. For example, `"namelookup"` is the
#' time returned by requesting `CURLINFO_NAMELOOKUP_TIME`. Refer to [curl
#' documentation] for explanations of what these measure. The most useful
#' component is likely `"total"`, the overall time to complete the request.
#'
#' [curl documentation]: https://everything.curl.dev/transfers/getinfo.html#available-information
#'
#' @inheritParams resp_header
#' @returns named numeric vector of timing information
#' @export
#' @examples
#' req <- request(example_url())
#' resp <- req_perform(req)
#' resp_timing(resp)
resp_timing <- function(resp) {
  check_response(resp)

  resp$timing
}
