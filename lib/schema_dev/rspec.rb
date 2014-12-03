require 'logger'
require 'pathname'

module SchemaDev
  module Rspec

    def self.db_connect
      env = JSON.parse(ENV['SCHEMA_DEV_ENV'])
      db = env['db']
      ruby = env['ruby']
      rails = env['rails']
      root = Pathname.new('tmp')
      root.mkpath
      configuration = case db
                      when 'mysql'
                        {
                          :adapter => 'mysql',
                          :database => 'schema_plus_test',
                          :username => ENV.fetch('MYSQL_DB_USER', 'schema_plus'),
                          :encoding => 'utf8',
                          :min_messages => 'warning'
                        }
                      when 'mysql2'
                        {
                          :adapter => 'mysql2',
                          :database => 'schema_plus_test',
                          :username => ENV.fetch('MYSQL_DB_USER', 'schema_plus'),
                          :encoding => 'utf8',
                          :min_messages => 'warning'
                        }
                      when 'postgresql'
                        {
                          :adapter => 'postgresql',
                          :username => ENV['POSTGRESQL_DB_USER'],
                          :database => 'schema_plus_test',
                          :min_messages => 'warning'
                        }
                      when 'sqlite3'
                        {
                          :adapter => 'sqlite3',
                          :database => root.join('schema_plus.sqlite3')
                        }
                      else
                        raise "Unknown db adapter #{db.inspect}"
                      end

      ActiveRecord::Base.logger = Logger.new(root.join("ruby-#{ruby}.rails-#{rails}.#{db}.log").open("w"))
      ActiveRecord::Base.configurations = { 'schema_dev' => configuration }
      ActiveRecord::Base.establish_connection :schema_dev

      case db
      when 'sqlite3'
        ActiveRecord::Base.connection.execute "PRAGMA synchronous = OFF"
      end


    end
  end
end
