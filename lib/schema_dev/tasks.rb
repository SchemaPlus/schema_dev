require_relative 'config'

dbms = SchemaDev::Config.load.dbms

DATABASES = %w[schema_plus_test]

if dbms.any?
  {
    postgresql: { uservar: 'POSTGRESQL_DB_USER', defaultuser: 'schema_plus', create: "createdb -U '%{user}' %{dbname}", drop: "dropdb -U '%{user}' %{dbname}" },
    mysql:      { uservar: 'MYSQL_DB_USER', defaultuser: 'schema_plus', create: "mysqladmin -u '%{user}' create %{dbname}", drop: "mysqladmin -u '%{user}' -f drop %{dbname}" }
  }.slice(*dbms).each do |dbm, info|
    namespace dbm do
      user = ENV.fetch info[:uservar], info[:defaultuser]
      task :create_databases do
        DATABASES.each do |dbname|
          system(info[:create] % {user: user, dbname: dbname})
        end
      end
      task :drop_databases do
        DATABASES.each do |dbname|
          system(info[:drop] % {user: user, dbname: dbname})
        end
      end
    end
  end

  desc 'Create test databases'
  task :create_databases do
    invoke_multiple(dbms, "create_databases")
  end

  desc 'Drop test databases'
  task :drop_databases do
    invoke_multiple(dbms, "drop_databases")
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
