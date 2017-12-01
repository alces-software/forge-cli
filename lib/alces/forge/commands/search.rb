require 'alces/forge/commands/command_base'
require 'colorize'

module Alces
  module Forge
    module Commands
      class Search < CommandBase
        def search(args, options)

          params = {
              :q => args[0]
          }

          [options.category].tap { |cats|
            if options.software
              cats << 'Software'
            end
            if options.config
              cats << 'Config'
            end
          }.compact.each do |cat|
            cats = params.fetch('cat[]') {
              params['cat[]'] = []  # Create an empty array if it doesn't yet exist
              # We do this here to avoid passing the cat[] param if it's not used
            }
            cats << cat
          end

          results = api.get('search', params: params )
          print_packages_list(results['packages'])
        end

        private

        def print_packages_list(packages)
          packages.each do |package_id, package|
            print_package(package)
          end
        end

        def print_package(package)
          puts "#{package['username']}/#{package['name'].bold}/#{package['version']} [#{categories_to_string(package)}]"
        end

        def categories_to_string(package)
          package['categories'].reverse.map { |c| coloured(c['name']) }.join(' > ')
        end

        def coloured(category)
          colour_index = (Digest::SHA1.hexdigest(category).to_i(16) % usable_colours.count)
          category.colorize(usable_colours[colour_index])
        end

        def usable_colours
          [
              :red,
              :light_red,
              :green,
              :light_green,
              :yellow,
              :light_yellow,
              :blue,
              :light_blue,
              :magenta,
              :light_magenta,
              :cyan,
              :light_cyan,
              :white,
              :light_white
          ]
        end
      end
    end
  end
end
