require 'alces/forge/api'

module Alces
  module Forge
    module Commands
      class CommandBase
        def api
          @api ||= ::Alces::Forge::API.new
        end
      end
    end
  end
end
