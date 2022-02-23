#' Use a proxy to connect to the internet.
#'
#' @param url,port location of proxy
#' @param username,password login details for proxy, if needed
#' @param auth type of HTTP authentication to use. Should be one of the
#'   following: basic, digest, digest_ie, gssnegotiate, ntlm, any.
#' @examples
#' # See http://www.hidemyass.com/proxy-list for a list of public proxies
#' # to test with
#' # request("http://had.co.nz") %>%
#' #   req_proxy("64.251.21.73", 8080) %>%
#' #   req_perform()
#' @export
req_proxy <- function(req, url, port = NULL, username = NULL, password = NULL, auth = "basic") {

  if (!is.null(username) || !is.null(password)) {
    proxyuserpwd <- paste0(username, ":", password)
  } else {
    proxyuserpwd <- NULL
  }

  if (!is.null(port)) stopifnot(is.numeric(port))

  req_options(
    req,
    proxy = url,
    proxyport = port,
    proxyuserpwd = proxyuserpwd,
    proxyauth = auth_flags(auth)
  )
}



auth_flags <- function(x = "basic") {

  constants <- c(
    basic = 1,
    digest = 2,
    gssnegotiate = 4,
    ntlm = 8,
    digest_ie = 16,
    any = -17
  )

  x <- match.arg(x, names(constants))

  constants[[x]]
}
