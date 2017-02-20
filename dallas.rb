require 'sinatra'
require 'app'
require 'rack/content_length' require 'jwt'
require 'oj'

set :session_secret, ENV['SESSION_SECRET']
enable :sessions

use Rack::ContentLength
use Rack::Logger

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
    token = authentication.generate_jwt_token
    payload = JWT.decode(token, nil, false)
    token + "\n" + Oj.dump(payload)
  end
end

get '/auth/:provider/callback', &CALLBACK_HANDLER
post '/auth/:provider/callback', &CALLBACK_HANDLER

get '/token.json' do
  verify_token do |auth|
    { uid: auth.uid,
      info: Oj.load(auth.info),
      credentials: auth.credentials && Oj.load(auth.credentials),
      extra: auth.extra && Oj.load(auth.extra)
    }.delete_if { |_,v| v.nil? }.to_json
  end
end

get '/status' do
  'OK'
end

def verify?
  unless auth_header = @request.env["HTTP_AUTHORIZATION"]
    @request.logger.error("fetch token: missing authorization header")
    return false
  end
  unless m = auth_header.match(/\AJWT (.*)\Z/)
    @request.logger.error("fetch token: invalid authorization header format")
    return false
  end
  token = m[1]
  begin
    unless unverified = JWT.decode(token, nil, false)
      @request.logger.error("fetch token: unable to decode token")
      return false
    end
    unless id = unverified.first['id']
      @request.logger.error("fetch token: missing id")
      return false
    end
    unless auth = Authentication.first(id: id)
      @request.logger.error("fetch token: auth not found")
      return false
    end
    unless auth.verify_jwt_token(token)
      @request.logger.error("fetch token: token verification failed")
      return false
    end
    return [true, auth]
  rescue Exception => err
    @request.logger.error("fetch token: " + err.to_s)
    @request.logger.error(err)
    return false
  end
end

def verify_token
  success, auth = verify?
  if success
    yield auth
  else
    status 401
    'Forbidden'
  end
end
