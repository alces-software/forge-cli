require 'rubygems'
require 'commander'
require 'alces/forge/commands/install'
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
          c.option '--category CATEGORY', String, 'Only show packages in category CATEGORY'
          c.option '--software', 'Only show software packages'
          c.option '--config', 'Only show configuration packages'
          c.action ::Alces::Forge::Commands::Search, :search
        end

        command :install do |c|
          c.syntax = 'forge install [options] user/package[/version]'
          c.summary = 'Install a Forge package'
          c.description = 'Download and install a Forge package.'
          c.example 'Install latest version of a package', 'alces forge install alces/somepackage'
          c.example 'Install a specific version of a package', 'alces forge install alces/somepackage/1.0.2'
          c.action ::Alces::Forge::Commands::Install, :install
        end

        run!
      end

    end
  end
end
