#' Is your computer currently online?
#'
#' This function uses some cheap heuristics to determine if your computer is
#' currently online. It's a simple wrapper around [curl::has_internet()]
#' exported from httr2 for convenience.
#'
#' @export
#' @examples
#' is_online()
is_online <- function() {
  curl::has_internet()
}
