require 'singleton'
require 'yaml'

module Alces
  module Forge
    class Config
      include Singleton

      class << self

        def has_key?(k)
          config.has_key?(k)
        end

        def method_missing(s, *a, &_)
          if config.has_key?(s)
            config[s]
          else
            nil
          end
        end

        def set(key, value)
          if value
            config[key.to_sym] = value
          else
            config.delete(key.to_sym)
          end
          save
        end

        def api_url
          ENV['cw_FORGE_API_URL'] || config[:api_url] || 'https://api.forge.alces-flight.com/v1'
        end

        def sso_url
          ENV['cw_FORGE_SSO_URL'] || config[:sso_url] || 'https://accounts.alces-flight.com'
        end

        private

        DEFAULT_CONFIG = {
        }

        CONFIG_DIRECTORY = '~/.config/clusterware/forge'
        CONFIG_FILE_PATH = "#{CONFIG_DIRECTORY}/config.yml"

        def config
          @config ||= DEFAULT_CONFIG.dup.tap { |cfg|
            # Merge in config settings here
            if File.exists?(user_config_file)
              cfg.merge!(YAML.load_file(user_config_file))
            end
          }
        end

        def user_config_dir
          File.expand_path(CONFIG_DIRECTORY)
        end

        def user_config_file
          File.expand_path(CONFIG_FILE_PATH)
        end

        def save
          unless Dir.exists?(user_config_dir)
            Dir.mkdir(user_config_dir, 0700)
          end
          File.write(user_config_file, config.to_yaml)
          File.chmod(0600, user_config_file)  # File may contain auth token so should not be world-readable!
        end

      end

    end
  end
end

