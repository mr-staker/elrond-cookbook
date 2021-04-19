require 'kitchen/transport/docker'

module Kitchen
  module Transport
    module ConnectionExt
      # add support for kitchen login
      def login_command
        LoginCommand.new 'docker', [
          'exec', '-it', options[:container_id], 'su', '-', 'kitchen'
        ]
      end
    end
  end
end

Kitchen::Transport::Docker::Connection.include Kitchen::Transport::ConnectionExt
