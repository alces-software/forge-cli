require 'alces/forge/commands/command_base'
require 'colorize'

module Alces
  module Forge
    module Commands
      class Search < CommandBase
        def search(args, options)
          results = api.get('search', params: {:q => args[0]} )
          print_packages_list(results['packages'])
        end

        private

        def print_packages_list(packages)
          packages.each do |package_id, package|
            print_package(package)
          end
        end

        def print_package(package)
          puts "#{package['username']}/#{package['name'].bold}/#{package['version']}"
        end
      end
    end
  end
end
