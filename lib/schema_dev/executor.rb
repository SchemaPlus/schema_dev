require 'json'
require_relative "ruby_selector"
require_relative "gemfile_selector"

module SchemaDev
  class Executor

    attr_reader :ruby, :rails, :db, :error

    def initialize(ruby:, rails:, db: nil)
      @ruby_selector = RubySelector.command(ruby)
      @gemfile_selector = GemfileSelector.command(rails: rails, db: db)
    end

    def run(cmd, dry_run: false)
      fullcommand = ["/usr/bin/env", @gemfile_selector, @ruby_selector, cmd].compact.join(' ')
      puts "* #{fullcommand}"
      return true if dry_run

      Tempfile.open('SchemaDev') do |file|
        @error = !system(%Q[ (#{fullcommand}) 2>& 1 | tee #{file.path} ])
        file.rewind
        @error ||= file.readlines.grep(/(^Failed examples)|(rake aborted)|(LoadError)/).any?
      end

      return !@error
    end
  end
end
