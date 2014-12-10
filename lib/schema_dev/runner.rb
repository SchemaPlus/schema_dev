require 'shellwords'

require_relative 'matrix_executor'
require_relative 'travis'

module SchemaDev
  class Runner
    def initialize(config)
      @config = config
    end

    def travis
      Travis.update(@config) and puts "* Updated #{filepath}"
    end

    def gemfiles
      Gemfiles.build(@config) and puts "* Created gemfiles"
    end

    def run(*args, dry_run: false, quick: false, ruby: nil, rails: nil, db: nil, freshen: true)
      self.travis if freshen

      matrix = MatrixExecutor.new @config.matrix(quick: quick, ruby: ruby, rails: rails, db: db)

      return true if matrix.run(Shellwords.join(args.flatten), dry_run: dry_run)

      puts "\n*** #{matrix.errors.size} failures:\n\t#{matrix.errors.join("\n\t")}"
      return false
    end
  end
end
