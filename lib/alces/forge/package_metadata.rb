require 'alces/forge/config'
require 'alces/forge/errors'
require 'json'
require 'semantic'
require 'zip'

module Alces
  module Forge

    PackagePath = Struct.new(:user, :package, :version)

    class PackageMetadata
      def self.load_from_api(api, user, package, version=nil)
        params = {
            'filter[username]' => user,
            'filter[name]' => package,
            :sort => '-version'
        }

        if version
          params['filter[version]'] = version
        else
          params['sort'] = '-version'  # 'Newest' first (assuming sensible ordering from the server)
          # NB We can't sort on the standard Rails attributes (createdAt / updatedAt) since these will all read the
          # same for the Alces autogenerated packages, and earlier versions might be added later anyway.
        end

        metadata = api.get('packages', params: params)['data'].first

        raise Errors::NoSuchPackageException.new("#{user}/#{package}/#{version || 'latest'}") unless metadata
        new(metadata)
      end

      def self.load_from_path(api, package_path)
        package_props = split_package_path(package_path)
        return load_from_api(api, package_props[:user], package_props[:package], package_props[:version])
      end

      def self.load_by_id(api, package_id)
        metadata = api.get("packages/#{package_id}/")['data']
        new(metadata)
      end

      def self.load_from_file(filename)
        Zip::File.open(filename) do |zipfile|
          metadata_file = zipfile.glob('metadata.json').first
          raise Errors::InvalidPackageException unless metadata_file
          new(JSON.parse(metadata_file.get_input_stream.read), true)
        end
      end

      def initialize(metadata, local_file=false)
        @metadata = metadata
        @local_file = local_file
      end

      def method_missing(s, *a, &_)
        s = s.to_s
        if metadata.has_key?(s)
          metadata[s]
        elsif metadata['attributes'].has_key?(s)
          metadata['attributes'][s]
        else
          nil
        end
      end

      def package_path
        "#{username}/#{name}/#{version}"
      end

      def id
        metadata['id']
      end

      def local_file?
        @local_file
      end

      private

      def metadata
        @metadata
      end

      def self.split_package_path(path)
        format_check = /^[^\/ ]+(\/[^\/ ]+){0,2}$/.match(path)
        raise 'Unrecognised package format. Please specify as [username/]packagename[/version]' unless format_check

        split = path.split('/')

        if split.length == 1
          # Just a package name; assume user is the default, version is nil (== latest)
          PackagePath.new(Config.default_user, split[0], nil)
        elsif split.length == 2
          # Could either be username/package or package/version, so let's try...
          begin
            Semantic::Version.new(split[1])
            PackagePath.new(Config.default_user, split[0], split[1])
          rescue
            if split[1] == 'latest'
              PackagePath.new(Config.default_user, split[0], nil)
            else
              PackagePath.new(split[0], split[1], nil)
            end
          end
        elsif split.length == 3
          # This one is easy but we should check the version number
          begin
            Semantic::Version.new(split[2])
            PackagePath.new(split[0], split[1], split[2])
          rescue
            if split[2] == 'latest'
              PackagePath.new(split[0], split[1], nil)
            else
              raise "'#{split[2]}' is not a valid version number."
            end
          end
        end
      end

    end
  end
end
