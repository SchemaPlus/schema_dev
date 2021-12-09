require 'schema_dev/config'
require 'schema_dev/rspec'

dbms = SchemaDev::Config.load.db

if dbms.any?
  (%w[postgresql, mysql2] & dbms).each do |dbm, info|
    namespace dbm do
      task :create_database do
        require 'active_record'

        config = SchemaDev::Rspec.db_configuration(dbm)

        ActiveRecord::Tasks::DatabaseTasks.create(config)
      end
      task :drop_databases do
        require 'active_record'

        config = SchemaDev::Rspec.db_configuration(dbm)

        ActiveRecord::Tasks::DatabaseTasks.drop(config)
      end
    end
  end

  desc 'Create database for CI run'
  task :create_ci_database do
    require 'active_record'

    config = SchemaDev::Rspec.db_configuration

    ActiveRecord::Tasks::DatabaseTasks.create(config) unless config['adapter'] == 'sqlite3'
  end

  desc 'Create test databases'
  task :create_databases do
    invoke_multiple(dbms, "create_database")
  end

  desc 'Drop test databases'
  task :drop_databases do
    invoke_multiple(dbms, "drop_database")
  end

  def invoke_multiple(namespaces, task)
    failed = namespaces.reject { |adapter|
      begin
        Rake::Task["#{adapter}:#{task}"].invoke
        true
      rescue => e
        warn "\n#{e}\n"
        false
      end
    }
    fail "Failure in: #{failed.join(', ')}" if failed.any?
  end
end
