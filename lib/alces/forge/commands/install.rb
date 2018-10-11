require 'alces/forge/cli_utils'
require 'alces/forge/commands/command_base'
require 'alces/forge/config'
require 'alces/forge/dependencies'
require 'alces/forge/package_file'
require 'alces/forge/package_metadata'
require 'alces/forge/registry'
require 'forwardable'
require 'http'
require 'tempfile'

module Alces
  module Forge
    module Commands

      class Install < CommandBase

        extend Forwardable
        def_delegators CLIUtils, :doing, :do_with_spinner, :say, :shell

        def install(args, options)

          check_sanity(options)

          metadata = get_package_metadata(args)

          say "Found package: " + "#{metadata.username}/#{metadata.name}".bold + " version #{metadata.version.bold}"

          if Registry.installed?(metadata) && !options.reinstall
            say 'Package is already installed! Use --reinstall to reinstall.'
            return false
          end

          to_install = do_with_spinner 'Resolving dependencies' do
            Dependencies.resolve(api, metadata)
                        .select do |package|
                          next true if options.reinstall
                          !Registry.installed?(package)
                        end
          end

          package_files = []

          dep_packages = to_install.reject(&:last?)
                                   .map { |p| p.package_path }
          say "Installing for dependencies: #{dep_packages.join(', ')}" unless dep_packages.empty?

          to_install.each do |candidate|
            package_file = do_with_spinner "Downloading #{candidate.package_path}" do
              PackageFile.for(candidate).tap { |pf|
                package_files << pf
                # We ensure the package file is downloaded and cached regardless of whether we are about to use it
                # immediately to install onto the master node.
                unless pf.cached? && !options.reinstall
                  pf.download
                end
              }
            end

            if should_install_on_compute_nodes(options)
              Registry.mark(candidate, :compute)
              say 'Package marked for installation on compute nodes.'
            end

            if should_install_here(options)
              Registry.mark(candidate, :master)

              do_with_spinner "Extracting #{candidate.package_path}" do
                package_file.extract
              end

              do_with_spinner "Installing #{candidate.package_path}" do
                package_file.install
              end

              Registry.set_installed(candidate)
            end
          end
        rescue Errors::NoSuchPackageException => e
            say "No package found for #{e.message}"
        ensure
          if package_files
            do_with_spinner 'Cleaning up' do
              package_files.each { |package_file|
                package_file.clean_up unless package_file.nil?
              }
            end
          end
        end

        private

        def get_package_metadata(args)
          package_path_or_file = args[0]

          if File.exists?(package_path_or_file)
            do_with_spinner 'Extracting metadata' do
              PackageMetadata.load_from_file(package_path_or_file).tap { |md|
                PackageFile.for_local(md, package_path_or_file).download
              }
            end
          else
            do_with_spinner 'Downloading metadata' do
              Forge::PackageMetadata.load_from_path(api, package_path_or_file)
            end
          end
        end

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
