# frozen_string_literal: true

require 'kitchen/driver/docker'
require 'kitchen/transport/docker'
require 'kitchen/docker/helpers/image_helper'

module Kitchen
  module Driver
    module DockerExt
      def verify_dependencies
        # rubocop:disable Chef/Deprecations/UsesRunCommandHelper
        # rubocop:disable Chef/Deprecations/ChefSugarHelpers
        run_command("#{config[:binary]} info >> #{dev_null} 2>&1", quiet: true, use_sudo: config[:use_sudo])
        # rubocop:enable Chef/Deprecations/UsesRunCommandHelper
        # rubocop:enable Chef/Deprecations/ChefSugarHelpers
      rescue
        raise UserError, 'You must first install the Docker CLI tool https://www.docker.com/get-started'
      end
    end
  end

  module Transport
    # extend Connection with custom login_command
    module ConnectionExt
      # add support for kitchen login
      def login_command
        LoginCommand.new 'docker', [
          'exec', '-it', options[:container_id], 'su', '-', 'kitchen'
        ]
      end
    end
  end

  module Docker
    module Helpers
      module ImageHelper
        def parse_image_id(output)
          output.each_line do |line|
            if line =~ /writing image (sha256:[[:xdigit:]]{64})(?: \d*\.\ds)? done/i
              img_id = line[/writing image (sha256:[[:xdigit:]]{64})(?: \d*\.\ds)? done/i, 1]
              return img_id
            end
            if line =~ /image id|build successful|successfully (?:built|tagged)/i
              img_id = line.split(/\s+/).last
              return img_id
            end
          end
          raise ActionFailed, 'Could not parse Docker build output for image ID'
        end
      end
    end
  end
end

Kitchen::Driver::Docker.include Kitchen::Driver::DockerExt
Kitchen::Transport::Docker::Connection.include Kitchen::Transport::ConnectionExt
