# frozen_string_literal: true

require 'logger'
require 'pathname'
require_relative '../gemfile_selector'

module SchemaDev
  module Rspec
    module Db
      extend self

      def setup
        set_logger
        connect
        RSpec.configure do |config|
          config.include Helpers
          config.filter_run_excluding postgresql: -> (v) {
            if Helpers.postgresql?
              case v
              when String
                version = ActiveRecord::Base.connection.select_value("SHOW server_version").match(/(\d+\.\d+)/)[1]
                postgresql_version = Gem::Version.new(version)
                test = Gem::Requirement.new(v)
                !test.satisfied_by?(postgresql_version)
              else
                v == :skip
              end
            else
              v == :only
            end
          }
          config.filter_run_excluding mysql: :only unless Helpers.mysql?
          config.filter_run_excluding mysql: :skip if Helpers.mysql?
          config.filter_run_excluding sqlite3: :only unless Helpers.sqlite3?
          config.filter_run_excluding sqlite3: :skip if Helpers.sqlite3?
          config.filter_run_excluding rails: -> (v) {
            rails_version = Gem::Version.new(ActiveRecord::VERSION::STRING)
            test = Gem::Requirement.new(v)
            !test.satisfied_by?(rails_version)
          }
        end
      end

      def tmproot
        @tmproot ||= Pathname.new('tmp').tap(&:mkpath)
      end

      def logroot
        @logroot ||= Pathname.new('log').tap(&:mkpath)
      end

      def database
        @database ||= 'schema_plus_test'
        # @database ||= (Dir["*.gemspec"].first || "schema_dev_test").sub(/\.gemspec$/, '') + "_test"
      end

      def configuration(db: nil)
        case db || infer_db
        when 'mysql'
          {
            'adapter'      => 'mysql',
            'database'     => database,
            'host'         => ENV['MYSQL_DB_HOST'],
            'username'     => ENV.fetch('MYSQL_DB_USER', 'schema_plus'),
            'password'     => ENV['MYSQL_DB_PASS'],
            'encoding'     => 'utf8',
            'min_messages' => 'warning'
          }
        when 'mysql2'
          {
            'adapter'      => 'mysql2',
            'database'     => database,
            'host'         => ENV['MYSQL_DB_HOST'],
            'username'     => ENV.fetch('MYSQL_DB_USER', 'schema_plus'),
            'password'     => ENV['MYSQL_DB_PASS'],
            'encoding'     => 'utf8',
            'min_messages' => 'warning'
          }
        when 'postgresql'
          {
            'adapter'      => 'postgresql',
            'database'     => database,
            'host'         => ENV['POSTGRESQL_DB_HOST'],
            'username'     => ENV['POSTGRESQL_DB_USER'],
            'password'     => ENV['POSTGRESQL_DB_PASS'],
            'min_messages' => 'warning'
          }
        when 'sqlite3'
          {
            'adapter'  => 'sqlite3',
            'database' => tmproot.join("#{database}.sqlite3").to_s
          }
        else
          raise "Unknown db adapter #{db.inspect}"
        end.compact
      end

      def infer_db
        @infer_db ||= GemfileSelector.infer_db
      end

      def connect
        ActiveRecord::Base.configurations = { 'schema_dev' => configuration }
        ActiveRecord::Base.establish_connection :schema_dev
        case infer_db
        when 'sqlite3'
          ActiveRecord::Base.connection.execute 'PRAGMA synchronous = OFF'
        end
      end

      def set_logger
        ruby = "#{RUBY_ENGINE}#{RUBY_VERSION}"
        activerecord = "activerecord#{ActiveRecord.version}"
        ActiveRecord::Base.logger = Logger.new(logroot.join("#{ruby}-#{activerecord}-#{infer_db}.log").open('w'))
      end

      module Helpers
        extend self

        def mysql?
          ActiveRecord::Base.connection.adapter_name =~ /^mysql/i
        end

        def postgresql?
          ActiveRecord::Base.connection.adapter_name =~ /^postgresql/i
        end

        def sqlite3?
          ActiveRecord::Base.connection.adapter_name =~ /^sqlite/i
        end
      end
    end
  end
end
