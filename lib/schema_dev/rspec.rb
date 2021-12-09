require_relative 'rspec/db'

module SchemaDev
  module Rspec

    def self.setup
      Db.setup
    end

    def self.db_configuration
      Db.configuration
    end

    module Helpers
      extend Rspec::Db::Helpers
    end
  end

end
