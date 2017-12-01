require 'alces/forge/cli_utils'
require 'alces/forge/config'
require 'forwardable'

module Alces
  module Forge
    module Commands
      class SSO < CommandBase

        extend Forwardable
        def_delegators CLIUtils,  :do_with_spinner

        def login(args, options)
          username = $terminal.ask('Please enter your Flight username: ')
          password = $terminal.ask('Please enter your password: ') { |e| e.echo = false }

          token = do_with_spinner 'Logging you in' do
            api.login(username, password)
          end

          Config.set(:auth_token, token)
          say 'You are now logged in to Alces Flight.'
        end

        def logout(args, options)
          Config.set(:auth_token, nil)
          say 'You are now logged out of Alces Flight.'
        end
      end
    end
  end
end
