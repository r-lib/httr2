req_options_set <- function(req, ...) {
  options <- list2(...)
  req$url$options <- utils::modifyList(req$url$options, options)
  req
}
