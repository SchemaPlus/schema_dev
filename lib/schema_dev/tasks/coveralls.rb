require 'coveralls/rake/task'
Coveralls::RakeTask.new
task :spec_with_coveralls => [:spec, 'coveralls:push']
