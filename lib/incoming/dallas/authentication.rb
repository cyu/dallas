require 'dm-postgres-types'
require 'jwt'

class Authentication
  include DataMapper::Resource

  JWT_ALGORITHM = 'HS256'

  property :id, Serial
  property :uid, String, required: true, unique_index: :uniqueness, length: 1..255
  property :authenticator_id, Integer, required: true, unique_index: :uniqueness
  property :info, PgJSON, required: true, load_raw_value: true
  property :credentials, PgJSON, load_raw_value: true
  property :extra, PgJSON, load_raw_value: true
  property :token, String, length: 1..255
  property :secret, String, length: 1..255
  property :expires, Boolean
  property :expires_at, DateTime
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :authenticator

  def info_hash
    Oj.load(info)
  end

  def generate_callback_url
    if url = authenticator.callback_url
      sep = url.index('?') ? '&' : '?'
      [url, generate_jwt_token].join(sep)
    end
  end

  def generate_jwt_token
    payload = {
      iss: authenticator.auth_strategy,
      iat: Time.now.to_i,
      id: id,
      name: info_hash['name'],
      email: info_hash['email'],
      nickname: info_hash['nickname'],
      given_name: info_hash['first_name'],
      last_name: info_hash['last_name'],
      picture: info_hash['image'],
      phone_number: info_hash['phone'],
      at_hash: token && Digest::MD5.hexdigest(token)
    }
    payload = payload.delete_if { |_,v| v.nil? }
    JWT.encode payload, authenticator.client.client_secret, JWT_ALGORITHM
  end

  def verify_jwt_token(token)
    !!JWT.decode(token, authenticator.client.client_secret, JWT_ALGORITHM)
  end

  def store_omniauth_auth(omniauth)
    self.info = Oj.dump(omniauth['info'].to_hash)
    store_omniauth_credentials(omniauth['credentials'])
    store_omniauth_extra(omniauth['extra'])
  end

  def store_omniauth_extra(omniauth)
    raw_info = omniauth.try(:[], 'raw_info')
    self.extra = raw_info.nil? ? nil : Oj.dump(raw_info.to_hash)
  end

  def store_omniauth_credentials(omniauth)
    self.credentials =
      self.token =
      self.secret =
      self.expires =
      self.expires_at = nil

    if omniauth
      self.credentials = Oj.dump(omniauth.to_hash)
      self.token = omniauth['token']
      self.secret = omniauth['secret']
      self.expires = omniauth['expires']
      self.expires_at = omniauth['expires_at']
    end
  end
end

