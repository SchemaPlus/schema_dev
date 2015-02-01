require 'pathname'

module SchemaDev
  GEMFILES_DIR = "gemfiles"

  module GemfileSelector
    extend self

    def gemfile(opts = {})
      opts = opts.keyword_args(activerecord: :required, db: :required)
      Pathname.new(GEMFILES_DIR).join("activerecord-#{opts.activerecord}", "Gemfile.#{opts.db}")
    end

    def command(opts={})
      opts = opts.keyword_args(activerecord: :required, db: :required)
      "BUNDLE_GEMFILE=#{gemfile(activerecord: opts.activerecord, db: opts.db)}"
    end

    def infer_db
      (env = ENV['BUNDLE_GEMFILE']) =~ %r{activerecord.*/Gemfile[.](.*)}
      $1 or raise "Can't infer db: Env BUNDLE_GEMFILE=#{env.inspect}) isn't a schema_dev standard Gemfile path.  (Run 'schema_dev rspec' instead of 'rspec'?)"
    end
  end
end
