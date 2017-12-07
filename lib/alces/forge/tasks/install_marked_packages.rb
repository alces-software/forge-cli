require 'alces/forge/api'
require 'alces/forge/package_file'
require 'alces/forge/package_metadata'
require 'alces/forge/registry'

module Alces
  module Forge
    module Tasks
      class << self
        def install_marked_packages

          instance_role = (ENV['cw_INSTANCE_role'] || 'compute').to_sym

          to_install = Registry.marked_packages(instance_role) - Registry.installed_packages

          puts "Found #{to_install.length} package(s) to install (node type: #{instance_role})"

          to_install.each do | package_path |
            begin

              puts "Installing #{package_path}"

              api = API.new

              metadata = PackageMetadata.load_from_path(api, package_path)
              package = PackageFile.for(metadata)

              raise "Package #{package_path} has not been downloaded and cached, unable to continue." unless package.cached?

              package.install

              Registry.set_installed(metadata)
              package.clean_up
            rescue Exception => e
              puts "Failed to install #{package_path}: #{e.message}"
            end
          end
        end
      end
    end
  end
end
