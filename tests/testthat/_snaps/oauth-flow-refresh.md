# warns if refresh token changes

    Code
      . <- oauth_flow_refresh(client, "abc")
    Condition
      Warning:
      Refresh token has changed! Please update stored value

