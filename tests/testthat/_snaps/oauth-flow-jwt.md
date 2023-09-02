# validates inputs

    Code
      oauth_flow_bearer_jwt(client1)
    Condition
      Error in `oauth_flow_bearer_jwt()`:
      ! JWT flow requires `client` with a key.

---

    Code
      oauth_flow_bearer_jwt(client2, claim = NULL)
    Condition
      Error in `oauth_flow_bearer_jwt()`:
      ! `claim` must be a list or function.

