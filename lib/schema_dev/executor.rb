require 'json'
require 'open3'

require_relative "ruby_selector"
require_relative "gemfile_selector"

module SchemaDev
  class Executor

    attr_reader :ruby, :activerecord, :db, :error

    def initialize(ruby:, activerecord:, db:)
      @ruby_selector = RubySelector.command(ruby)
      @gemfile_selector = GemfileSelector.command(activerecord: activerecord, db: db)
    end

    def run(cmd, dry_run: false)
      fullcommand = ["/usr/bin/env", @gemfile_selector, @ruby_selector, cmd].compact.join(' ')
      puts "* #{fullcommand}"
      return true if dry_run

      @error = false
      Open3.popen2e(fullcommand) do |i, oe, t|
        oe.each {|line|
          puts line
          @error ||= (line =~ /(^Failed examples)|(rake aborted)|(LoadError)/)
        }
        @error ||= !t.value.success?
      end

      return !@error
    end
  end
end
