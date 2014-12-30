require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'coveralls/rake/task'
Coveralls::RakeTask.new
task :travis => [:spec, 'coveralls:push']
