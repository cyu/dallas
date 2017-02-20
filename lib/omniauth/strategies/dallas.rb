require 'omniauth'
require 'oj'

module OmniAuth
  module Strategies
    class Dallas
      include OmniAuth::Strategy

      AUTHENTICATOR = 'dallas.authenticator'.freeze
      CONTENT_TYPE = 'Content-Type'.freeze
      TEXT_PLAIN = 'text/plain'.freeze

      option :base_domain

      def call!(env)
        request = Rack::Request.new(env)
        subdomain = calculate_subdomain(request)
        return @app.call(env) unless subdomain
        auth = Authenticator.first(subdomain: subdomain)
        return not_found unless auth
        env[AUTHENTICATOR] = auth
        middleware = OmniAuth::Strategies.const_get(OmniAuth::Utils.camelize(auth.auth_strategy.to_s).to_s)
        opts = Oj.load(auth.strategy_options)
        args = opts.delete('_args')
        provider = middleware.new(@app, *args, opts.merge(callback_path: callback_path, request_path: request_path))
        provider.call!(env)
      end

      def calculate_subdomain(req)
        if m = req.host.match(domain_regex)
          m[1]
        else
          nil
        end
      end

      def domain_regex
        @domain_regex ||= Regexp.compile("\\A(.*?)\\.#{Regexp.quote(options[:base_domain])}\\Z")
      end

      def not_found
        [404, {CONTENT_TYPE => TEXT_PLAIN}, ["Not Found"]]
      end
    end
  end
end
