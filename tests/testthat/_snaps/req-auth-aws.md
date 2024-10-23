# validates its inputs

    Code
      req_auth_aws_v4(1)
    Condition
      Error in `req_auth_aws_v4()`:
      ! `req` must be an HTTP request object, not the number 1.
    Code
      req_auth_aws_v4(req, 1)
    Condition
      Error in `req_auth_aws_v4()`:
      ! `aws_access_key_id` must be a single string, not the number 1.
    Code
      req_auth_aws_v4(req, "", "", aws_session_token = 1)
    Condition
      Error in `req_auth_aws_v4()`:
      ! `aws_session_token` must be a single string or `NULL`, not the number 1.
    Code
      req_auth_aws_v4(req, "", "", aws_service = 1)
    Condition
      Error in `req_auth_aws_v4()`:
      ! `aws_service` must be a single string or `NULL`, not the number 1.
    Code
      req_auth_aws_v4(req, "", "", aws_region = 1)
    Condition
      Error in `req_auth_aws_v4()`:
      ! `aws_region` must be a single string or `NULL`, not the number 1.

