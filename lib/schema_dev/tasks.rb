require_relative 'tasks/dbms'
require_relative 'tasks/coveralls'

task :travis => :spec_with_coveralls
