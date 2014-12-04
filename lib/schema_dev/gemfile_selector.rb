require 'pathname'

module SchemaDev
  GEMFILES_DIR = "gemfiles"

  module GemfileSelector
    def self.gemfile(rails:, db: nil)
      root = Pathname.new(GEMFILES_DIR)
      if db
        root.join("rails-#{rails}", "Gemfile.#{db}")
      else
        root.join("Gemfile.#{rails}")
      end
    end

    def self.command(rails:, db: nil)
      "BUNDLE_GEMFILE=#{gemfile(rails: rails, db: db)}"
    end

    def self.infer_db
      (env = ENV['BUNDLE_GEMFILE']) =~ %r{rails.*/Gemfile[.](.*)}
      $1 or raise "Can't infer db: Env BUNDLE_GEMFILE=#{env.inspect}) isn't a schema_dev Gemfile path with db"
    end
  end
end
