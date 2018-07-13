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
          ENV['cw_FORGE_API_URL'] || config[:api_url] || 'https://forge-api.alces-flight.com/v1'
        end

        def sso_url
          ENV['cw_FORGE_SSO_URL'] || config[:sso_url] || 'https://accounts.alces-flight.com'
        end

        private

        DEFAULT_CONFIG = {
            default_user: 'alces',
            package_cache_dir: "#{ENV['FL_ROOT']}/var/forge/cache/packages"
        }

        CONFIG_DIRECTORY = "#{ENV['FL_ROOT']}/etc/forge"
        CONFIG_FILE_PATH = "#{CONFIG_DIRECTORY}/config.yml"

        def config
          @config ||= DEFAULT_CONFIG.dup.tap { |cfg|
            # Merge in config settings here
            if File.exists?(CONFIG_FILE_PATH)
              cfg.merge!(YAML.load_file(CONFIG_FILE_PATH))
            end
          }
        end

        def save
          unless Dir.exists?(CONFIG_DIRECTORY)
            Dir.mkdir(CONFIG_DIRECTORY, 0700)
          end
          File.write(CONFIG_FILE_PATH, config.to_yaml)
          File.chmod(0600, CONFIG_FILE_PATH)  # File may contain auth token so should not be world-readable!
        end

      end

    end
  end
end

