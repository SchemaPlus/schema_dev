# frozen_string_literal: true

require_relative 'executor'

module SchemaDev
  class MatrixExecutor
    attr_reader :errors

    def initialize(matrix)
      @matrix = matrix
    end

    def run(cmd, dry_run: false)
      @errors = []
      @matrix.each_with_index do |tuple, i|
        ruby = tuple[:ruby]
        activerecord = tuple[:activerecord]
        db = tuple[:db]

        label = "ruby #{ruby} - activerecord #{activerecord} - db #{db}"
        msg = "#{label} [#{i + 1} of #{@matrix.size}]"
        puts "\n\n*** #{msg}\n\n"

        if not Executor.new(ruby: ruby, activerecord: activerecord, db: db).run(cmd, dry_run: dry_run)
          @errors << label
        end
      end
      @errors.empty?
    end
  end
end
