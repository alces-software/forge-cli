require 'http'

module Alces
  module Forge
    class API

      def initialize
        if ENV['FORGE_API_URL']
          @base_url = ENV['FORGE_API_URL'].chomp('/')
        else
         raise 'No URL specified for Forge API. Please specify FORGE_API_URL environment variable'
        end
      end

      def get(endpoint)
        http.get("#{@base_url}/#{endpoint}")
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
