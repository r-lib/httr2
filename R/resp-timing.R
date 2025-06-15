#' Extract timing data
#'
#' The underlying curl library measures how long different components of the
#' request take to complete. This function retrieves that information.
#'
#' @inheritParams resp_header
#' @returns Named numeric vector of timing information.
#'  The names of the elements in this vector correspond to the names used
#'  in [libcurl's `curl_easy_getinfo()` API][curl docs].
#'  The most useful component is likely `"total"` (corresponding to
#'  `CURLINFO_TOTAL_TIME`), the overall time in seconds to complete the
#'  request including any redirects followed.
#'
#'  [curl docs]: https://curl.se/libcurl/c/curl_easy_getinfo.html
#' @export
#' @examples
#' req <- request(example_url())
#' resp <- req_perform(req)
#' resp_timing(resp)
resp_timing <- function(resp) {
  check_response(resp)

  resp$timing
}
