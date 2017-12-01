require 'alces/forge/cli_utils'
require 'alces/forge/commands/command_base'
require 'alces/forge/package_metadata'
require 'forwardable'
require 'http'
require 'open3'
require 'tempfile'

module Alces
  module Forge
    module Commands

      class Install < CommandBase

        extend Forwardable
        def_delegators CLIUtils, :doing, :do_with_spinner, :say, :shell

        def install(args, options)
          package_props = split_package_path(args[0])

          metadata = do_with_spinner 'Downloading metadata' do
            Forge::PackageMetadata.load_from_api(api, package_props[:user], package_props[:package], package_props[:version])
          end

          say "Found package: #{metadata.name.bold} version #{metadata.version.bold}"

          package = download_package(metadata.packageUrl)

          extracted_dir = extract_package(package)

          run_installer(extracted_dir)

          package.unlink
          FileUtils.remove_entry(extracted_dir)

        end

        private

        def split_package_path(path)
          match = /(?<user>[^\/]+)\/(?<package>[^\/]+)(\/(?<version>[^\/]+))?/.match(path)

          raise 'Unrecognised package format. Please specify as username/packagename[/version]' unless match

          match
        end

        def download_package(url)
          temp = Tempfile.new('forge-dl')
          temp.binmode
          do_with_spinner 'Downloading' do
            body = HTTP.get(url).body
            while (part = body.readpartial) do
              temp.write(part)
            end
            temp.close
          end
          temp
        end

        def extract_package(package_file)
          dest = Dir.mktmpdir('forge-install')

          do_with_spinner 'Extracting' do
            shell("unzip \"#{package_file.path}\"", dest)
          end
          dest
        end

        def run_installer(dir)
          do_with_spinner 'Installing' do
            File.chmod(0700, File.join(dir, 'install.sh'))
            shell('./install.sh', dir)
          end

        end

      end
    end
  end
end
