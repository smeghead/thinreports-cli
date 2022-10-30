require 'json'
require 'thinreports'

module Thinreports
  module Cli
    module Commands
      class Generate

        def initialize(parameter_path, destination_path)
          @parameter_path = parameter_path
          @destination_path = destination_path
        end

        def call
          parameter = load_parameter

          report = Thinreports::Report.new

          # parameter のデータに従いページ毎に値を設定する。
          parameter['pages'].each do |page|
            report.start_new_page layout: page['template'] do |p|
              page['items'].each do |name, value|
                if ! p.item_exists?(name.to_sym)
                  $stderr.puts sprintf('WARNING: No such item. This item will ignored. (page: %d, key: `%s`)', p.no, name)
                  next
                end
                p.item(name.to_sym).value(value['value'])
              end
            end
          end
          report.generate(filename: destination_path)
        end

        private

        attr_reader :parameter_path, :destination_path

        def load_parameter
          error "No such file - #{parameter_path}" unless File.exist?(parameter_path)
          JSON.parse(File.read(parameter_path, encoding: 'UTF-8'))
        end

        def error(message)
          raise Thor::Error, message
        end

      end
    end
  end
end
