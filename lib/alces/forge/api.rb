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

      private

      def http
        HTTP.headers(
          user_agent: 'Forge-CLI/0.0.1'
        )
      end

    end
  end
end
