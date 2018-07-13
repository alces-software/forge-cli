require 'singleton'
require 'yaml'

module Alces
  module Forge
    class Registry
      include Singleton
      # The registry records packages that have been selected for installation, either on the master node or compute nodes
      # (or both); and also packages that have actually been installed on the local node.

      REGISTRY_DIR = "#{ENV['FL_ROOT']}/var/forge/registers"
      MASTER_REGISTRY_PATH = File.join(REGISTRY_DIR, 'master.yml')
      LOCAL_REGISTRY_PATH = File.join(REGISTRY_DIR, 'local.yml')

      DEFAULT_LOCAL_REGISTRY = {packages: [] }
      DEFAULT_MASTER_REGISTRY = {master: [], compute: []}

      class << self

        def installed_packages
          local[:packages]
        end

        def installed?(metadata)
          installed_packages.include?(metadata.package_path)
        end

        def set_installed(metadata)
          unless installed_packages.include?(metadata.package_path)
            installed_packages << metadata.package_path
            save_local
          end
        end

        def marked_packages(node_type)
          unless master.include?(node_type)
            master[node_type] = []
          end
          master[node_type]
        end

        def mark(metadata, node_type)
          unless marked_packages(node_type).include?(metadata.package_path)
            marked_packages(node_type) << metadata.package_path
            save_master
          end
        end

        private

        def master
          @master ||= load(MASTER_REGISTRY_PATH, DEFAULT_MASTER_REGISTRY)
        end

        def local
          @local ||= load(LOCAL_REGISTRY_PATH, DEFAULT_LOCAL_REGISTRY)
        end

        def load(file, default=nil)
          YAML.load_file(file) rescue default
        end

        def save_local
          save(LOCAL_REGISTRY_PATH, local.to_yaml)
        end

        def save_master
          save(MASTER_REGISTRY_PATH, master.to_yaml)
        end

        def save(path, data)
          dir = File.dirname(path)
          unless Dir.exists?(dir)
            FileUtils.mkdir_p(dir)
          end
          File.write(path, data)
        end
      end
    end
  end
end
