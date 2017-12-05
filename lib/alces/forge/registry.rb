require 'singleton'
require 'yaml'

module Alces
  module Forge
    class Registry
      include Singleton
      # The registry records packages that have been selected for installation, either on the master node or compute nodes
      # (or both); and also packages that have actually been installed on the local node.

      MASTER_REGISTRY_DIR = '/opt/forge/var/lib'
      MASTER_REGISTRY_PATH = File.join(MASTER_REGISTRY_DIR, 'registry.yml')

      LOCAL_REGISTRY_DIR = "#{ENV['cw_ROOT']}/etc/forge"
      LOCAL_REGISTRY_PATH = File.join(LOCAL_REGISTRY_DIR, 'local.yml')

      DEFAULT_REGISTRY_CONTENT = { packages: [] }

      class << self

        def installed_packages
          local[:packages]
        end

        def installed?(metadata)
          installed_packages.include?(metadata.package_path)
        end

        def set_installed(metadata)
          installed_packages << metadata.package_path
          save_local
        end

        private

        def master
          @master ||= load(MASTER_REGISTRY_PATH)
        end

        def local
          @local ||= load(LOCAL_REGISTRY_PATH)
        end

        def load(file)
          YAML.load_file(file) rescue DEFAULT_REGISTRY_CONTENT
        end

        def save_local
          unless Dir.exists?(LOCAL_REGISTRY_DIR)
            FileUtils.mkdir_p(LOCAL_REGISTRY_DIR)
          end
          File.write(LOCAL_REGISTRY_PATH, local.to_yaml)
        end

      end

    end
  end
end
