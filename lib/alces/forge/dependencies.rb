module Alces
  module Forge
    class Dependencies
      class << self

        def resolve(api, metadata)

          to_install = [ ]
          to_resolve = [ metadata ]
          resolved_ids = [ ]

          until to_resolve.empty?
            current = to_resolve.pop
            #puts "Resolving #{current.id}"
            to_install << current

            deps_metadata = current.dependencies.map { |dep_id|
              PackageMetadata.load_by_id(api, dep_id)
            }
            #puts "deps for #{current.id}: #{deps_metadata}"

            # We want to install these dependencies and resolve any further dependencies they have
            to_resolve += deps_metadata.reject { |dep| resolved_ids.include?(dep.id) }
            #puts "to_resolve now #{to_resolve}"

            resolved_ids << current.id

          end

          to_install.reverse.uniq { |p| p.id }
        end

      end
    end
  end
end
