require 'pathname'

module SchemaDev
  GEMFILES_DIR = "gemfiles"

  module GemfileSelector
    extend self

    def gemfile(opts = {})
      opts = opts.keyword_args(rails: :required, db: nil)
      root = Pathname.new(GEMFILES_DIR)
      if opts.db
        root.join("rails-#{opts.rails}", "Gemfile.#{opts.db}")
      else
        root.join("Gemfile.rails-#{opts.rails}")
      end
    end

    def command(opts={})
      opts = opts.keyword_args(rails: :required, db: nil)
      "BUNDLE_GEMFILE=#{gemfile(rails: opts.rails, db: opts.db)}"
    end

    def infer_db
      (env = ENV['BUNDLE_GEMFILE']) =~ %r{rails.*/Gemfile[.](.*)}
      $1 or raise "Can't infer db: Env BUNDLE_GEMFILE=#{env.inspect}) isn't a schema_dev Gemfile path with db"
    end
  end
end
