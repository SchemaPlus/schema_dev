require 'pathname'

module SchemaDev
  GEMFILES_DIR = "gemfiles"

  module GemfileSelector
    def self.gemfile(opts = {})
      opts = opts.keyword_args(rails: :required, db: nil)
      root = Pathname.new(GEMFILES_DIR)
      if db
        root.join("rails-#{opts.rails}", "Gemfile.#{opts.db}")
      else
        root.join("Gemfile.#{opts.rails}")
      end
    end

    def self.command(opts={})
      opts = opts.keyword_args(rails: :required, db: nil)
      "BUNDLE_GEMFILE=#{gemfile(rails: opts.rails, db: opts.db)}"
    end

    def self.infer_db
      (env = ENV['BUNDLE_GEMFILE']) =~ %r{rails.*/Gemfile[.](.*)}
      $1 or raise "Can't infer db: Env BUNDLE_GEMFILE=#{env.inspect}) isn't a schema_dev Gemfile path with db"
    end
  end
end
