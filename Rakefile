require 'bundler/gem_tasks'
require 'rake/testtask'

task default: :spec

Rake::TestTask.new do |test|
    test.test_files = Dir['test/**/test_*.rb']
    test.verbose = true
end