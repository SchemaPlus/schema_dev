require 'shellwords'

require_relative 'matrix_executor'

module SchemaDev
  class Runner
    def initialize(config)
      @config = config
    end

    def run(*args, dry_run: false, quick: false, ruby: nil, rails: nil, db: nil)
      matrix = MatrixExecutor.new @config.matrix(quick: quick, ruby: ruby, rails: rails, db: db)

      return true if matrix.run(Shellwords.join(args.flatten), dry_run: dry_run)

      puts "\n*** #{matrix.errors.size} failures:\n\t#{matrix.errors.join("\n\t")}"
      return false
    end
  end
end
