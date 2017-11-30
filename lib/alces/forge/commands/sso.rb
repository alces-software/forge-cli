require 'alces/forge/config'

module Alces
  module Forge
    module Commands
      class SSO < CommandBase
        def login(args, options)
          username = $terminal.ask('Please enter your Flight username: ')
          password = $terminal.ask('Please enter your password: ') { |e| e.echo = false }

          token = api.login(username, password)

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
