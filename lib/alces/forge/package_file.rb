require 'alces/forge/cli_utils'
require 'forwardable'

module Alces
  module Forge
    class PackageFile

      extend Forwardable
      def_delegators CLIUtils, :shell

      def self.for(metadata)
        new(metadata, nil)
      end

      def self.for_local(metadata, file)
        new(metadata, file)
      end

      def cached?
        File.exists?(download_cache_file)
      end

      def from_cache
        download_cache_file
      end

      def download
        dl_target_dir = download_cache_path
        unless Dir.exists?(dl_target_dir)
          FileUtils.mkdir_p(dl_target_dir)
        end

        if @local_file
          FileUtils.cp(@local_file, download_cache_file)
        elsif !@metadata.local_file?
          target = File.open(download_cache_file, 'wb')
          body = HTTP.get(@metadata.packageUrl).body
          while (part = body.readpartial) do
            target.write(part)
          end
          target.close
        end
        download_cache_file
      end

      def extract
        dest = Dir.mktmpdir('forge-install')

        shell("unzip \"#{download_cache_file}\"", dest)
        @extracted_dir = dest
        dest
      end

      def install
        raise 'Cannot install a package before it has been downloaded.' unless cached?

        extract unless @extracted_dir && Dir.exists?(@extracted_dir)

        File.chmod(0700, File.join(@extracted_dir, 'install.sh'))
        shell('./install.sh', @extracted_dir)
      end

      def clean_up
        if !@extracted_dir.nil? && Dir.exists?(@extracted_dir)
          FileUtils.remove_entry(@extracted_dir)
        end
      end

      private

      def initialize(metadata, local_file)
        @metadata = metadata
        @local_file = local_file
      end

      def download_cache_path
        File.join(Config.package_cache_dir, @metadata.username, @metadata.name)
      end

      def download_cache_file
        File.join(download_cache_path, @metadata.version)
      end
    end
  end
end
