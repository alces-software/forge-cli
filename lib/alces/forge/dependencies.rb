require 'alces/forge/errors'
require 'alces/forge/registry'

module Alces
  module Forge
    class Dependencies
      class << self

        def resolve(api, metadata)
          resolve_level(api, metadata).sort_by {|p| -p[:level]}
                                      .map {|p| p[:package]}
                                      .uniq { |p| p.id }
        end

        private

        def resolve_level(api, metadata, level=0)

          deps_metadata = metadata.dependencies.map do |raw_dep|
            dep = Registry.installed_version(raw_dep) || raw_dep
            PackageMetadata.load_from_path(api, dep)
          end

          deps = deps_metadata.map do |dep|
            resolve_level(api, dep, level + 1)
          end

          deps.flatten << {level: level, package: metadata}
        end

      end
    end
  end
end
