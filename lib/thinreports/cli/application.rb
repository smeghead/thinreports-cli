require 'thor'
require_relative 'commands/upgrade'
require_relative 'commands/generate'

module Thinreports
  module Cli
    class Application < Thor
      desc 'upgrade', 'Upgrade .tlf to 0.9.x from 0.8.x.'
      def upgrade(source_path, destination_path)
        Commands::Upgrade.new(source_path, destination_path).call
      end

      desc 'generate', 'Generate PDF.'
      def generate(source_path, destination_path)
        Commands::Generate.new(source_path, destination_path).call
      end
    end
  end
end
