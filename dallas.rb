require 'sinatra'
require 'app'
require 'rack/content_length'
require 'jwt'
require 'oj'

set :session_secret, ENV['SESSION_SECRET']
enable :sessions

use Rack::ContentLength

use OmniAuth::Builder do
  provider :dallas
end

CALLBACK_HANDLER = lambda do
  omniauth = env['omniauth.auth']
  authenticator = env['dallas.authenticator']
  created, authentication = authenticator.store_omniauth_auth(omniauth)
  if callback_url = authentication.generate_callback_url
    redirect callback_url
  else
    status(created ? 201 : 200)
    payload = JWT.decode(authentication.generate_jwt_token, nil, false)
    Oj.dump(payload)
  end
end

get '/auth/:provider/callback', &CALLBACK_HANDLER
post '/auth/:provider/callback', &CALLBACK_HANDLER
