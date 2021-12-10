# frozen_string_literal: true

require 'pathname'

module SchemaDev
  GEMFILES_DIR = 'gemfiles'

  module GemfileSelector
    extend self

    def gemfile(activerecord:, db:)
      Pathname.new(GEMFILES_DIR).join("activerecord-#{activerecord}", "Gemfile.#{db}")
    end

    def command(activerecord:, db:)
      "BUNDLE_GEMFILE=#{gemfile(activerecord: activerecord, db: db)}"
    end

    def infer_db
      (env = ENV['BUNDLE_GEMFILE']) =~ %r{activerecord.*/Gemfile[.](.*)}
      $1 or raise "Can't infer db: Env BUNDLE_GEMFILE=#{env.inspect}) isn't a schema_dev standard Gemfile path.  (Run 'schema_dev rspec' instead of 'rspec'?)"
    end
  end
end
