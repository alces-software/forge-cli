require 'rubygems'
require 'commander'
require 'alces/forge/commands/search'

module Alces
  module Forge
    class CLI
      include Commander::Methods

      def run
        program :name, 'forge'
        program :version, '0.0.1'
        program :description, 'Alces Flight Forge CLI'

        command :search do |c|
          c.syntax = 'forge search [options] searchterm'
          c.summary = 'Search for packages on Forge'
          c.description = 'Search for packages on Forge.'
          c.example 'Perform a search for "genetics"', 'alces forge search genetics'
          c.action ::Alces::Forge::Commands::Search, :search
        end

        command :install do |c|
          c.syntax = 'forge install [options]'
          c.summary = ''
          c.description = ''
          c.example 'description', 'command example'
          c.option '--some-switch', 'Some switch that does something'
          c.action do |args, options|
            # Do something or c.when_called Forge::Commands::Install
          end
        end

        run!
      end

    end
  end
end
