require 'alces/forge/cli_utils'
require 'alces/forge/commands/command_base'
require 'alces/forge/config'
require 'alces/forge/package_file'
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

          metadata = do_with_spinner 'Downloading metadata' do
            Forge::PackageMetadata.load_from_path(api, args[0])
          end

          say "Found package: #{metadata.name.bold} version #{metadata.version.bold}"

          package_file = PackageFile.for(metadata)

          # We ensure the package file is downloaded and cached regardless of whether we are about to use it
          # immediately to install onto the master node.
          unless package_file.cached? && !options.reinstall
            do_with_spinner 'Downloading' do
              package_file.download
            end
          end

          if should_install_on_compute_nodes(options)
            Registry.mark(metadata, :compute)
            say 'Package marked for installation on compute nodes.'
          end

          if should_install_here(options)
            Registry.mark(metadata, :master)

            if Registry.installed?(metadata) && !options.reinstall
              say 'Package is already installed! Use --reinstall to reinstall.'
            else

              do_with_spinner 'Extracting' do
                package_file.extract
              end

              do_with_spinner 'Installing' do
                package_file.install
              end

              Registry.set_installed(metadata)
            end
          end
        ensure
          do_with_spinner 'Cleaning up' do
            package_file.clean_up unless package_file.nil?
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

      end
    end
  end
end
