require 'pathname'

module SchemaDev
  GEMFILES_DIR = "gemfiles"

  module GemfileSelector
    extend self

    def gemfile(opts = {})
      opts = opts.keyword_args(rails: :required, db: :required)
      Pathname.new(GEMFILES_DIR).join("rails-#{opts.rails}", "Gemfile.#{opts.db}")
    end

    def command(opts={})
      opts = opts.keyword_args(rails: :required, db: :required)
      "BUNDLE_GEMFILE=#{gemfile(rails: opts.rails, db: opts.db)}"
    end

    def infer_db
      (env = ENV['BUNDLE_GEMFILE']) =~ %r{rails.*/Gemfile[.](.*)}
      $1 or raise "Can't infer db: Env BUNDLE_GEMFILE=#{env.inspect}) isn't a schema_dev standard Gemfile path"
    end
  end
end
