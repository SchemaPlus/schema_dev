# frozen_string_literal: true

require_relative 'rspec/db'

module SchemaDev
  module Rspec
    def self.setup
      Db.setup
    end

    def self.db_configuration(db: nil)
      Db.configuration(db: db)
    end

    module Helpers
      extend Rspec::Db::Helpers
    end
  end
end
