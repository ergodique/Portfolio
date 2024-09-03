# Using the Client

The client is used to make api calls and start streaming data from the Schwab API.  
In order to use all api calls you must have both "APIs" added to your app, both "Accounts and Trading Production" and "Market Data Production"

It is recommended to store your app keys and app secret in a dot-env file `.env` especially if you are using a git repo.
With a github repo you can include `*.env` and `tokens.json` in the `.gitignore` file to stop your credentials from getting commited. 

Making a client is as simple as:
```py
import schwabdev

client = schwabdev.Client(app_key, app_secret)
```
And from here on "client" can be used to make api calls via `client.XXXX()`, all calls are outlined in `tests/api_demo.py` and `docs/api.md`.  
Now lets look at all of the parameters that can be passed to the client constructor:
> Syntax: `client = schwabdev.Client(app_key, app_secret, callback_url="https://127.0.0.1", tokens_file="tokens.json", timeout=5, verbose=False, update_tokens_auto=True)`
> * Param app_key(str): app key to use, 32 chars long.  
> * Param app_secret(str): app secret to use, 16 chars long.  
> * Param callback_url(str): callback url to use, must be https and not end with a slash "/".  
> * Param tokens_file(str): path to tokens file.  
> * Param timeout(int): timeout to use when making requests.  
> * Param verbose(bool): verbose (print extra information).  
> * Param update_tokens_auto(bool): thread that checks/updats the access token and refresh token (requires user input).


The Schwab API uses two tokens to use the api:
* Refresh token - valid for 7 days, used to "refresh" the access token.
* Access token - valid for 30 minutes, used in all api calls.   

If you want to access the access or refresh tokens you can call `client.access_token` or `client.refresh_token`.  
The access token can be easily updated/refreshed assuming that the refresh token is valid, getting a new refresh token, however, requires user input. It is recommended force-update the refresh token during weekends so it is valid during the week, this can be done with the call: `client.update_tokens(force=True)`, or by changing the date in `tokens.json`.

## Common Issues

> Problem: Trying to sign into account and get error message: "We are unable to complete your request. Please contact customer service for further assistance."  
> Fix: Your app is "Approved - Pending", you must wait for status "Ready for Use".  
> Note: Or you *could* have an account type that is not supported by the Schwab API.

> Problem: SSL: CERTIFICATE_VERIFY_FAILED - self-signed certificate in certificate chain error when connecting to streaming server  
> Fix: For MacOS you must run the python certificates installer: `open /Applications/Python\ 3.12/Install\ Certificates.command`

> Problem: Issues with option contracts in api calls or streaming:  
> Fix: You are likely not following the format for option contracts.   
> Option contract format: Symbol (6 characters including spaces!) | Expiration (6 characters) | Call/Put (1 character) | Strike Price (5+3=8 characters)

> Problem: API calls throwing errors despite access token and refresh token being valid / not expired.  
> Fix: Manually update refresh / access tokens by calling `client.update_tokens(force=True)`; You can also delete the tokens.json file.

> Problem: Streaming ACCT_ACTIVITY yields no responses.   
> Fix: This is a known issue on Schwab's end.

> Problem: After signing in, you get a "Access Denied" web page.  
> Fix: Your callback url is likely incorrect due to a slash "/" at the end.

> Problem: App Registration Error  
> Fix: email Schwab (traderapi@schwab.com)

> Problem: Issue in streaming with websockets - "Unsupported extension: name = permessage-deflate, params = []"  
> Cause: You are using a proxy that is blocking streaming or your DNS is not correctly resolving.  
> Fix: Change DNS servers (Google's are known-working) or change/bypass proxy.

> Problem: refresh token expiring in 7 days is too short. - I know. 




