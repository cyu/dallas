require 'securerandom'

class Client
  include DataMapper::Resource

  property :id, Serial
  property :name, String, required: true
  property :client_key, String, required: true, length: 1..255
  property :client_secret, String, required: true, length: 1..255
  property :created_at, DateTime
  property :updated_at, DateTime
  property :callback_url, String, length: 1..255

  has n, :authenticators

  before :valid?, :ensure_credentials

  def ensure_credentials
    self.client_key ||= SecureRandom.hex
    self.client_secret ||= SecureRandom.hex
  end

end

