#' @examples
#' creds <- paws.common::locate_credentials("bedrock")
#' model_id <- "anthropic.claude-3-5-sonnet-20240620-v1:0"
#' req <- request("https://bedrock-runtime.us-east-1.amazonaws.com")
#' # https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_Converse.html
#' req <- req_url_path_append(req, "model", model_id, "converse")
#' req <- req_body_json(req, list(
#'   messages = list(list(
#'     role = "user",
#'     content = list(list(text = "What's your name?"))
#'   ))
#' ))
#' req <- req_sign_aws_v4_auth(
#'   req,
#'   "bedrock",
#'   aws_access_key_id = creds$access_key_id,
#'   aws_secret_access_key = creds$secret_access_key,
#'   aws_session_token = creds$session_token,
#'   aws_region = creds$region
#' )
#' resp <- req_perform_connection(req)
#' str(resp_body_json(resp))
#'
# https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_sigv-create-signed-request.html
req_sign_aws_v4_auth <- function(req,
                                 aws_service,
                                 aws_access_key_id     = Sys.getenv("AWS_ACCESS_KEY_ID"),
                                 aws_secret_access_key = Sys.getenv("AWS_SECRET_ACCESS_KEY"),
                                 aws_session_token     = Sys.getenv("AWS_SESSION_TOKEN"),
                                 aws_region            = Sys.getenv("AWS_DEFAULT_REGION"),
                                 current_time          = Sys.time()) {

  body_sha256 <- openssl::sha256(req_body_get(req))

  # We begin by adding some necessary headers that must be added before
  # canoncalization even thought they aren't documented until later
  req <- req_aws_headers(req,
    current_time = current_time,
    aws_session_token = aws_session_token,
    body_sha256 = body_sha256
  )

  authorization_header <- aws_v4_signature(
    method = req_method_get(req),
    url = url_parse(req$url),
    headers = req$headers,
    body_sha256 = body_sha256,
    current_time = current_time,
    aws_service = aws_service,
    aws_region = aws_region,
    aws_access_key_id = aws_access_key_id,
    aws_secret_access_key = aws_secret_access_key
  )
  req_headers(req, Authorization = authorization_header)
}

req_aws_headers <- function(req, current_time, aws_session_token, body_sha256) {
  RequestDateTime <- format(current_time, "%Y%m%dT%H%M%SZ", tz = "UTC")

  req_headers(
    req,
    "x-amz-date" = RequestDateTime,
    "x-amz-content-sha256" = body_sha256, # necessary for S3
    "x-amz-security-token" = aws_session_token
  )
}

aws_v4_signature <- function(method,
                             url,
                             headers,
                             body_sha256,
                             current_time = Sys.time(),
                             aws_service,
                             aws_region,
                             aws_access_key_id,
                             aws_secret_access_key) {
  # 1. Create a canonical request
  # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_sigv-create-signed-request.html#create-canonical-request
  HTTPMethod <- method
  CanonicalURI <- curl::curl_escape(url$path %||% "/")
  # AWS does not want / to be encoded here
  CanonicalURI <- gsub("%2F", "/", CanonicalURI, fixed = TRUE)

  if (is.null(url$query)) {
    CanonicalQueryString <- ""
  } else {
    sorted_query <- url$query[order(names(url$query))]
    CanonicalQueryString <- query_build(CanonicalQueryString)
  }

  headers$host <- url$hostname
  names(headers) <- tolower(names(headers))
  headers <- headers[order(names(headers))]
  headers[] <- trimws(headers)
  headers[] <- gsub(" {2,}", " ", headers)
  CanonicalHeaders <- paste0(names(headers), ":", headers, "\n", collapse = "")
  SignedHeaders <- paste0(names(headers), collapse = ";")

  CanonicalRequest <- paste0(
    HTTPMethod, "\n",
    CanonicalURI, "\n",
    CanonicalQueryString, "\n",
    CanonicalHeaders, "\n",
    SignedHeaders, "\n",
    body_sha256
  )
  # 2. Create the hash of the canonical request
  # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_sigv-create-signed-request.html
  HashedCanonicalRequest <- openssl::sha256(CanonicalRequest)

  # 3. Create the string to sign
  # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_sigv-create-signed-request.html#create-string-to-sign

  Algorithm <- "AWS4-HMAC-SHA256"
  RequestDateTime <- format(current_time, "%Y%m%dT%H%M%SZ", tz = "UTC")
  Date <- format(current_time, "%Y%m%d", tz = "UTC")
  CredentialScope <- file.path(Date, aws_region, aws_service, "aws4_request")

  string_to_sign <- paste0(
    Algorithm, "\n",
    RequestDateTime, "\n",
    CredentialScope, "\n",
    HashedCanonicalRequest
  )

  # 4. Derive a signing key
  # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_sigv-create-signed-request.html#derive-signing-key

  DateKey <- hmac_sha256(paste0("AWS4", aws_secret_access_key), Date)
  DateRegionKey <- hmac_sha256(DateKey, aws_region)
  DateRegionServiceKey <- hmac_sha256(DateRegionKey, aws_service)
  SigningKey <- hmac_sha256(DateRegionServiceKey, "aws4_request")

  # 5. Calculate signature
  # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_sigv-create-signed-request.html#calculate-signature

  signature <- hmac_sha256(SigningKey, string_to_sign)
  signature <- paste0(as.character(signature), collapse = "")

  # 6. Add the signature to the request
  # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_sigv-create-signed-request.html#calculate-signature
  credential <-  file.path(aws_access_key_id, CredentialScope)

  paste0(
    Algorithm, ",",
    "Credential=",    credential, ",",
    "SignedHeaders=", SignedHeaders, ",",
    "Signature=",     signature
  )
}

hmac_sha256 <- function(key, value) {
  openssl::sha256(charToRaw(value), key)
}
