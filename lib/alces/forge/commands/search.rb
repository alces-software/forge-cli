require 'alces/forge/api'

module Alces
  module Forge
    module Commands
      class Search
        def search(args, options)
          @api = ::Alces::Forge::API.new
          p args, options
        end
      end
    end
  end
end
