require 'colorize'
require 'open3'

module Alces
  module Forge
    module CLIUtils
      LOG_FILE = File.join(ENV['FLIGHT_DIRECT_ROOT'], 'var/log/forge.log')

      class ShellException < RuntimeError
      end

      class << self

        def tty?
          stream.tty?
        end

        def stream
          ($terminal.instance_variable_get :@output)
        end

        def say(msg)
          $terminal.say(msg)
        end

        def doing(msg, width = 12, &block)
          say(sprintf("    #{"%#{width}s".colorize(:cyan)} ... ",msg))
        end

        def with_spinner(&block)
          if !tty? || ENV['FLIGHT_DIRECT_NO_SPINNER']
            block.call
          else
            begin
              stream.print ' '
              spinner = Thread.new do
                spin = '|/-\\'
                i = 0
                loop do
                  stream.print "\b#{spin[i]}"
                  sleep 0.2
                  i = 0 if (i += 1) == 4
                end
              end
              block.call
            ensure
              spinner.kill
              stream.print "\b \b"
            end
          end
        end

        def do_with_spinner(msg, &block)
          doing msg

          exc = nil
          result = nil

          with_spinner do
            begin
              result = block.call
            rescue Exception => e
              exc = e
            end
          end

          if exc
            say 'Failed'.red
            raise exc
          else
            say 'Done'.green
          end

          result

        end

        def shell(cmd, working_dir=nil)
          Bundler.with_clean_env do
            stdout, stderr, status = ::Open3.capture3(shell_env, cmd, :chdir=>working_dir)

            write_logs(working_dir, cmd, stdout, stderr)

            unless status.success?
              raise ShellException.new(stderr)
            end
            stdout
          end
        end

        def shell_env
          {
              'BUNDLE_GEMFILE' => nil,
              'cw_UI_disable_spinner' => 'true'
          }
        end

        def write_logs(wd, cmd, stdout, stderr)
          FileUtils.mkdir_p File.dirname(LOG_FILE)
          open(LOG_FILE, 'a') do |log|
            log.write("#{DateTime.now} - running #{cmd} in #{wd}\n")
            log.write("--- stdout ---\n")
            log.write(stdout)
            log.write("--- stderr ---\n")
            log.write(stderr)
            log.write("-- complete --\n")
          end
        end
      end
    end
  end
end
