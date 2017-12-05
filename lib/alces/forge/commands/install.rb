require 'alces/forge/cli_utils'
require 'alces/forge/commands/command_base'
require 'alces/forge/config'
require 'alces/forge/package_metadata'
require 'alces/forge/registry'
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

          check_sanity(options)

          package_props = split_package_path(args[0])

          metadata = do_with_spinner 'Downloading metadata' do
            Forge::PackageMetadata.load_from_api(api, package_props[:user], package_props[:package], package_props[:version])
          end

          say "Found package: #{metadata.name.bold} version #{metadata.version.bold}"

          # We ensure the package file is downloaded and cached regardless of whether we are about to use it
          # immediately to install onto the master node.
          package_file = download_or_cached_package(metadata)

          if should_install_on_compute_nodes(options)
            Registry.mark(metadata, :compute)
            say 'Package marked for installation on compute nodes.'
          end

          if should_install_here(options)
            Registry.mark(metadata, :master)

            if Registry.installed?(metadata) && !options.reinstall
              say 'Package is already installed! Use --reinstall to reinstall.'
            else

              extracted_dir = extract_package(package_file)

              run_installer(extracted_dir)

              FileUtils.remove_entry(extracted_dir)
              Registry.set_installed(metadata)
            end
          end
        end

        private

        def check_sanity(options)
          if options.compute_only && options.everywhere
            raise '--compute-only and --everywhere are mutually exclusive. Please specify at most one.'
          end
        end

        def should_install_here(options)
          !options.compute_only
        end

        def should_install_on_compute_nodes(options)
          options.everywhere || options.compute_only
        end

        def split_package_path(path)
          match = /(?<user>[^\/]+)\/(?<package>[^\/]+)(\/(?<version>[^\/]+))?/.match(path)

          raise 'Unrecognised package format. Please specify as username/packagename[/version]' unless match

          match
        end

        def download_cache_path(metadata)
          File.join(Config.package_cache_dir, metadata.username, metadata.name)
        end

        def download_cache_file(metadata)
          File.join(download_cache_path(metadata), metadata.version)
        end

        def download_or_cached_package(metadata)
          target = download_cache_file(metadata)
          if File.exists?(target)
            target
          else
            download_package(metadata)
          end
        end

        def download_package(metadata)
          dl_target_dir = download_cache_path(metadata)
          unless Dir.exists?(dl_target_dir)
            FileUtils.mkdir_p(dl_target_dir)
          end

          target = File.open(download_cache_file(metadata), 'wb')
          do_with_spinner 'Downloading' do
            body = HTTP.get(metadata.packageUrl).body
            while (part = body.readpartial) do
              target.write(part)
            end
            target.close
          end
          target.path
        end

        def extract_package(package_file)
          dest = Dir.mktmpdir('forge-install')

          do_with_spinner 'Extracting' do
            shell("unzip \"#{package_file}\"", dest)
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
