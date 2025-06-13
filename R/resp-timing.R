#' Extract information about the timing of the response
#'
#' The underlying curl library measures how long different components of the
#' request take to complete. This function retrieves that information.
#'
#' The names of the elements in this vector correspond to the names used
#' in libcurl's `curl_easy_getinfo()` API. For example, `"namelookup"` is the
#' time returned by requesting `CURLINFO_NAMELOOKUP_TIME`. Refer to [curl
#' documentation] for explanations of what these measure. The most useful
#' component is likely `"total"`, the overall time in seconds to complete the
#' request including any redirects followed.
#'
#' [curl documentation]: https://curl.se/libcurl/c/curl_easy_getinfo.html
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
