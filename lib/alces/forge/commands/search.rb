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
          print_packages_list(results['packages'].sort_by { |package_id, package| [package['username'], package['name'], package['version']] } )
        end

        private

        def print_packages_list(packages)
          packages.each do |package_id, package|
            print_package(package)
          end
        end

        def print_package(package)
          print_string = "#{package['username']}/#{package['name']}".bold
          print_string += "/#{package['version']}"
          print_string += categories_to_string(package)
          puts print_string
        end

        def categories_to_string(package)
          # We don't want to display 'Uncategorised' as a category.
          displayable_categories = package['categories'].reject { |c| c['name'] == 'Uncategorised'}
          if displayable_categories.empty?
            ''
          else
            # Reversing gets us the list of categories starting with the oldest grandparent.
            "[#{displayable_categories.reverse.map { |c| coloured(c['name']) }.join(' > ') }]"
          end
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
