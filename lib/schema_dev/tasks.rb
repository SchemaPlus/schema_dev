require_relative 'tasks/dbms'
require_relative 'tasks/coveraalls'

task :travis => :spec_with_coveralls
