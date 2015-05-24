# oauth-slack-discourse
_________

**Slack API Oauth2 for Discourse**

Installation Instructions (for Docker installations): 

* Register a new Slack API application at: https://api.slack.com/applications/new if you haven't already
  * For the Redirect URL: http(s)://example.com/auth/slack/callback
* Open your container app.yml
* Under section ```env:``` you should add your Slack APP API credentials: 

**Warning:** the **CLIENT_ID** should be a **String** (as it has a dot and otherwise Rails will consider it a FixNum and take away the last two digits)
```
  SLACK_CLIENT_ID: 'CLIENT_ID'
  SLACK_CLIENT_SECRET: 'CLIENT_SECRET'
  SLACK_TEAM_ID: 'SLACK_TEAM_ID' (optional)
```
If **no** ```SLACK_TEAM_ID``` enviroment variable is set up it will ask the user the team with which he/she wants to sign up to Discourse

* Under section ```hooks``` add the follow line:
```
          - git clone https://github.com/4xposed/oauth-slack-discourse.git
```
* Rebuild the docker container

```
./launcher rebuild my_image
```