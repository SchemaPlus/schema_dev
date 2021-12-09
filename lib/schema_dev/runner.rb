require 'shellwords'

require_relative 'matrix_executor'
require_relative 'github_actions'
require_relative 'gemfiles'
require_relative 'readme'

module SchemaDev
  class Runner
    def initialize(config)
      @config = config
    end

    def github_actions(quiet: false)
      if GithubActions.update(@config)
        puts "* Updated #{GithubActions::WORKFLOW_FILE}" unless quiet
      end
    end

    def gemfiles(quiet: false)
      if Gemfiles.build(@config)
        puts "* Updated gemfiles" unless quiet
      end
    end

    def readme(quiet: false)
      if Readme.update(@config)
        puts "* Updated README" unless quiet
      end
    end

    def freshen(quiet: false)
      self.github_actions(quiet: quiet)
      self.gemfiles(quiet: quiet)
      self.readme(quiet: quiet)
    end

    def run(*args, dry_run: false, quick: false, ruby: nil, activerecord: nil, db: nil, freshen: true)
      self.freshen if freshen

      matrix = MatrixExecutor.new @config.matrix(quick: quick, ruby: ruby, activerecord: activerecord, db: db)

      return true if matrix.run(Shellwords.join(args.flatten), dry_run: dry_run)

      puts "\n*** #{matrix.errors.size} failures:\n\t#{matrix.errors.join("\n\t")}"
      return false
    end
  end
end
