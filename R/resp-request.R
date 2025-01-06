#' Find the request responsible for a response
#'
#' To make debugging easier, httr2 includes the request that was used to
#' generate every response. You can use this function to access it.
#'
#' @inheritParams resp_header
#' @export
#' @examples
#' req <- request_test()
#' resp <- req_perform(req)
#' resp_request(resp)
resp_request <- function(resp) {
  check_response(resp)

  resp$request
}
