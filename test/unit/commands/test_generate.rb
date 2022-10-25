require 'pathname'
require 'minitest/autorun'
require "minitest/reporters"
require 'thor'
require './lib/thinreports/cli/commands/generate'

Minitest::Reporters.use!

TEST_ROOT = Pathname.new(__FILE__).dirname.parent.parent

class GenerateTest < Minitest::Test

  def setup
  end

  def test_generate_initialize
    generate = Thinreports::Cli::Commands::Generate.new('path/to/parameter.json', 'path/to/output.pdf')
    assert generate, 'instance is not empty'
  end

  def test_source_file_not_exist_error
    generate = Thinreports::Cli::Commands::Generate.new('path/to/parameter.json', 'path/to/output.pdf')
    exp = assert_raises(Thor::Error) do
        generate.call
    end
    assert_equal 'No such file - path/to/parameter.json', exp.message
  end

  def test_normal_generation
    parameterJson = TEST_ROOT.join('data/generate/parameter.json').to_s()
    outputPdf = TEST_ROOT.join('data/generate/output.pdf').to_s()
    generate = Thinreports::Cli::Commands::Generate.new(parameterJson, outputPdf)
    generate.call
    assert_equal '%PDF-', File.read(outputPdf)[0..4], '4 bytes of file head.'
    File.delete(outputPdf)
  end
end