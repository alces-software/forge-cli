require 'alces/forge/errors'

module Alces
  module Forge
    class Dependencies
      class << self

        def resolve(api, metadata)
          resolve_level(api, metadata)
              .sort_by {|p| -p[:level]}
              .map {|p| p[:package]}
              .uniq { |p| p.id }
        end

        private

        def resolve_level(api, metadata, level=0)

          deps_metadata = metadata.dependencies.map { |dep|
            PackageMetadata.load_from_path(api, dep)
          }

          deps = deps_metadata.map { |dep| resolve_level(api, dep, level + 1)}

          deps.flatten << {level: level, package: metadata}
        end

      end
    end
  end
end
