require 'thor'
require_relative 'commands/upgrade'
require_relative 'commands/generate'

module Thinreports
  module Cli
    class Application < Thor
      desc 'upgrade [SOURCE_PATH] [DESTINATION_PATH]', 'Upgrade .tlf to 0.9.x from 0.8.x.'
      def upgrade(source_path, destination_path)
        Commands::Upgrade.new(source_path, destination_path).call
      end

      desc 'generate [PARAMETER_PATH] [DESTINATION_PATH]', 'Generate PDF. '
      long_desc <<-EOD
        PARAMETER_PATH is json file(see `example/parameter.json`).
        DESTINATION_PATH is path that will generated PDF file.
      EOD
      def generate(parameter_path, destination_path)
        Commands::Generate.new(parameter_path, destination_path).call
      end
    end
  end
end
