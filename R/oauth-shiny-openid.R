oauth_shiny_client_openid_config <- function(client) {
  if (is.null(client$openid_issuer_url)) {
    return(NULL)
  }
  url <- url_parse(client$openid_issuer_url)
  url$path <- paste0(sub("/$", "", url$path), "/.well-known/openid-configuration")

  req <- request(url_build(url))
  req <- req_perform(req)
  config <- resp_body_json(req)
  config
}

oauth_shiny_client_openid_resolve_urls <- function(client, openid_config = NULL) {
  if (!is.null(client$auth_url) && !is.null(client$token_url)) {
    return(client)
  }

  if (is.null(openid_config)) {
    openid_config <- oauth_shiny_client_openid_config(client)
  }

  if (is.null(client$auth_url)) {
    client$auth_url <- openid_config$authorization_endpoint
  }

  if (is.null(client$token_url)) {
    client$token_url <- openid_config$token_endpoint
  }

  client
}

oauth_shiny_client_openid_get_public_keys <- function(client, openid_config) {
  if (is.null(openid_config)) {
    openid_config <- oauth_shiny_client_openid_config(client)
  }
  req <- request(openid_config$jwks_uri)
  req <- req_perform(req)
  jwks <- resp_body_json(req, simplifyDataFame = FALSE)
  key_names <- lapply(jwks$keys, function(x) x[["kid"]])
  keys <- lapply(jwks$keys, function(x) jose::jwk_read(jsonlite::toJSON(x)))
  set_names(keys, key_names)
}

oauth_shiny_client_openid_verify_claims <- function(client, openid_config, token) {
  id_token <- token$id_token
  kid <- jose::jwt_split(id_token)[["header"]][["kid"]]
  keys <- oauth_shiny_client_openid_get_public_keys(client, openid_config)
  key <- keys[[kid]]

  claims <- jose::jwt_decode_sig(id_token, key)

  if (claims$aud != client$id) {
    cli::cli_abort("Audience mismatch")
  }

  if (sub("/$", "", claims$iss) != sub("/$", "", client$openid_issuer_url)) {
    cli::cli_abort("Issuer mismatch")
  }

  claims
}
