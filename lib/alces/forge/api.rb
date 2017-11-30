require 'alces/forge/config'
require 'http'
require 'json'

module Alces
  module Forge
    class API

      def initialize
          @base_url = Config.api_url.chomp('/')
      end

      def get(endpoint, *kwargs)
        JSON.parse(http.get("#{@base_url}/#{endpoint}", *kwargs).to_s)
      end

      def login(username, password)
        sso_base_url = Config.sso_url.chomp('/')

        response = http.post(
            "#{sso_base_url}/sign-in",
            params: {
                permanent: 1
            },
            json: {
                account: {
                    username: username,
                    password: password
                }
            }
        )

        if !response.status.success?
          raise response.to_s
        else
          JSON.parse(response.to_s)['user']['authentication_token']
        end
      end

      private

      def http
        h = HTTP.headers(
          user_agent: 'Forge-CLI/0.0.1'
        )
        if Config.auth_token
          h.auth("Bearer #{Config.auth_token}")
        else
          h
        end
      end

    end
  end
end
