require 'omniauth'
require 'rack_subdomains'
require 'oj'

module OmniAuth
  module Strategies
    class Dallas
      include OmniAuth::Strategy

      AUTHENTICATOR = 'dallas.authenticator'.freeze
      CONTENT_TYPE = 'Content-Type'.freeze
      TEXT_PLAIN = 'text/plain'.freeze

      def call!(env)
        request = Rack::Request.new(env)
        subdomain = request.subdomains.join('.')
        return not_found if subdomain == ''
        auth = Authenticator.first(subdomain: subdomain)
        return not_found unless auth
        env[AUTHENTICATOR] = auth
        middleware = OmniAuth::Strategies.const_get(OmniAuth::Utils.camelize(auth.auth_strategy.to_s).to_s)
        opts = Oj.load(auth.strategy_options)
        args = opts.delete('_args')
        provider = middleware.new(@app, *args, opts.merge(callback_path: callback_path, request_path: request_path))
        provider.call!(env)
      end

    end
  end
end
