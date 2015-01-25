require_relative 'rspec/db'

module SchemaDev
  module Rspec

    def self.setup
      Db.setup
    end

    def self.setup_db
      ActiveSupport::Deprecation.warn "SchemaDev::Rspec.setup_db is deprecated.  Use SchemaDev::Rspec.setup"
      self.setup
    end

    def self.db_configuration
      Db.configuration
    end

    module Helpers
      extend Rspec::Db::Helpers
    end
  end

end
