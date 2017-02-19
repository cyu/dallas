require 'dm-postgres-types'
require 'oj'

class Authenticator
  include DataMapper::Resource

  property :id, Serial
  property :subdomain, String, required: true, unique: true, unique_index: :subdomain
  property :auth_strategy, String, required: true
  property :strategy_options, PgJSON, required: true, load_raw_value: true
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :authentications
  belongs_to :client

  def callback_url
    client.callback_url
  end

  def store_omniauth_auth(omniauth)
    uid = omniauth['uid']
    auth = authentications.first(uid: uid) || authentications.new(uid: uid)
    created = auth.new?
    auth.store_omniauth_auth(omniauth)
    auth.raise_on_save_failure = true
    auth.valid?
    p auth.errors
    auth.save
    [created, auth]
  end

end
