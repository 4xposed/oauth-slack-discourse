# name: Slack Oauth2 Discourse
# about: This plugin allows your users to sign up/in using their Slack account.
# version: 0.3
# authors: Daniel Climent
# url: https://github.com/4xposed/oauth-slack-discourse

require 'auth/oauth2_authenticator'
require 'omniauth-oauth2'

class SlackAuthenticator < ::Auth::OAuth2Authenticator

  CLIENT_ID = ENV['SLACK_CLIENT_ID']
  CLIENT_SECRET = ENV['SLACK_CLIENT_SECRET']
  TEAM_ID = ENV['SLACK_TEAM_ID']

  def name
    'slack'
  end

  def after_authenticate(auth_token)
    result = Auth::Result.new

    # Grab the info we need from OmniAuth
    data = auth_token[:info]

    provider = auth_token[:provider]
    slack_uid = auth_token["uid"]

    result.name = data[:name]
    result.username = data[:nickname]
    result.email = data[:email]

    result.email_valid = true
    result.extra_data = { uid: slack_uid, provider: provider }

    current_info = ::PluginStore.get("slack", "slack_uid_#{slack_uid}")

    if User.find_by_email(data[:email]).nil?
      user = User.create(name: data[:name], email: data[:email], username: data[:nickname], approved: true)
      ::PluginStore.set("slack", "slack_uid_#{slack_uid}",{user_id: user.id})
    end

    result.user =
        if current_info
          User.where(id: current_info[:user_id]).first
        elsif user = User.where(username: result.username).first
          user
        end
    result.user ||= User.where(email: data[:email]).first

    result
  end

  def after_create_account(user, auth)
    data = auth[:extra_data]
    user.update_attribute(:approved, true)
    ::PluginStore.set("slack", "slack_uid_#{data[:uid]}", {user_id: user.id})
  end

  def register_middleware(omniauth)
    unless TEAM_ID.nil?
     omniauth.provider :slack, CLIENT_ID, CLIENT_SECRET, scope: 'identify, users:read', team: TEAM_ID
    else
     omniauth.provider :slack, CLIENT_ID, CLIENT_SECRET, scope: 'identify, users:read'
    end
  end
end

class OmniAuth::Strategies::Slack < OmniAuth::Strategies::OAuth2
  # Give your strategy a name.
  option :name, "slack"

  option :authorize_options, [ :scope, :team ]

  option :client_options, {
    site: "https://slack.com",
    token_url: "/api/oauth.access"
  }

  option :auth_token_params, {
    mode: :query,
    param_name: 'token'
  }

  uid { raw_info['user_id'] }

  info do
    {
      name: user_info['user']['profile']['real_name_normalized'],
      email: user_info['user']['profile']['email'],
      nickname: user_info['user']['name']
    }
  end

  extra do
    { raw_info: raw_info, user_info: user_info }
  end

  def user_info
    @user_info ||= access_token.get("/api/users.info?user=#{raw_info['user_id']}").parsed
  end

  def raw_info
    @raw_info ||= access_token.get("/api/auth.test").parsed
  end
end

auth_provider title: 'with Slack',
    message: 'Log in using your Slack account. (Make sure your popup blocker is disabled.)',
    frame_width: 920,
    frame_height: 800,
    authenticator: SlackAuthenticator.new('slack', trusted: true)

register_css <<CSS

  .btn-social.slack {
    background: #08c;
    text-indent: 19px;
  }

  .btn-social.slack:before {
    content: "\xf198";
  }

CSS
