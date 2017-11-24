require 'colorize'

module Alces
  module Forge
    module CLIUtils

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
          if !tty?
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

          with_spinner do
            begin
              block.call
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

        end

        def shell(cmd, working_dir=nil)
          old_pwd = Dir.pwd

          if working_dir
            Dir.chdir(working_dir)
          end

          stdout, stderr, status = ::Open3.capture3(cmd)

          Dir.chdir(old_pwd)

          unless status.success?
            raise ShellException.new(stderr)
          end
          stdout
        end
      end
    end
  end
end
