# Sign a request with the AWS SigV4 signing protocol

This is a custom auth protocol implemented by AWS.

## Usage

``` r
req_auth_aws_v4(
  req,
  aws_access_key_id,
  aws_secret_access_key,
  aws_session_token = NULL,
  aws_service = NULL,
  aws_region = NULL
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- aws_access_key_id, aws_secret_access_key:

  AWS key and secret.

- aws_session_token:

  AWS session token, if required.

- aws_service, aws_region:

  The AWS service and region to use for the request. If not supplied,
  will be automatically parsed from the URL hostname.

## Examples

``` r
if (FALSE) { # httr2:::has_paws_credentials()
creds <- paws.common::locate_credentials()
model_id <- "anthropic.claude-3-5-sonnet-20240620-v1:0"
req <- request("https://bedrock-runtime.us-east-1.amazonaws.com")
# https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_Converse.html
req <- req_url_path_append(req, "model", model_id, "converse")
req <- req_body_json(req, list(
  messages = list(list(
    role = "user",
    content = list(list(text = "What's your name?"))
  ))
))
req <- req_auth_aws_v4(
  req,
  aws_access_key_id = creds$access_key_id,
  aws_secret_access_key = creds$secret_access_key,
  aws_session_token = creds$session_token
)
resp <- req_perform_connection(req)
str(resp_body_json(resp))
}
```
