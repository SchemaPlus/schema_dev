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
  end
end
