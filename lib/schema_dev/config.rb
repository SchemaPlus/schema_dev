require 'active_support/core_ext/hash'
require 'enumerator'
require 'fastandand'
require 'its-it'
require 'key_struct'
require 'pathname'
require 'yaml'
require 'hash_keyword_args'

module SchemaDev
  CONFIG_FILE = "schema_dev.yml"

  class Config

    attr_accessor :quick, :db, :ruby, :rails, :notify, :exclude

    def self._reset ; @@config = nil end  # for use by rspec

    def self.read
      new((YAML.load Pathname.new(CONFIG_FILE).read).symbolize_keys)
    end

    def self.load
      @@config ||= read
    end

    def initialize(opts={}) # once we no longer support ruby 1.9.3, can switch to native keyword args
      opts = opts.keyword_args(ruby: :required, rails: :required, db: :required, exclude: nil, notify: nil, quick: nil)
      @ruby = Array.wrap(opts.ruby)
      @rails = Array.wrap(opts.rails)
      @db = Array.wrap(opts.db)
      @exclude = Array.wrap(opts.exclude).map(&:symbolize_keys).map {|tuple| Tuple.new(tuple)}
      @notify = Array.wrap(opts.notify)
      @quick = Array.wrap(opts.quick || {ruby: @ruby.last, rails: @rails.last, db: @db.last})
    end

    def dbms
      @dbms ||= [:postgresql, :mysql].select{|dbm| @db.grep(/^#{dbm}/).any?}
    end

    def matrix(opts={}) # once we no longer support ruby 1.9.3, can switch to native keyword args
      opts = opts.keyword_args(quick: false, ruby: nil, rails: nil, db: nil, excluded: nil)
      use_ruby = @ruby
      use_rails = @rails
      use_db = @db
      if opts.quick
        use_ruby = @quick.map{|q| q[:ruby]}
        use_rails = @quick.map{|q| q[:rails]}
        use_db = @quick.map{|q| q[:db]}
      end
      use_ruby = Array.wrap(opts.ruby) if opts.ruby
      use_rails = Array.wrap(opts.rails) if opts.rails
      use_db = Array.wrap(opts.db) if opts.db

      use_ruby = [nil] unless use_ruby.any?
      use_rails = [nil] unless use_rails.any?
      use_db = [nil] unless use_db.any?

      m = use_ruby.product(use_rails, use_db)
      m = m.map { |_ruby, _rails, _db| Tuple.new(ruby: _ruby, rails: _rails, db: _db) }.compact
      m = m.reject(&it.match_any?(@exclude)) unless opts.excluded == :none
      m = m.map(&:to_hash)

      if opts.excluded == :only
        return matrix(opts.merge(excluded: :none)) - m
      else
        return m
      end
    end

    class Tuple < KeyStruct[:ruby, :rails, :db]
      def match?(other)
        return false if self.ruby and other.ruby and self.ruby != other.ruby
        return false if self.rails and other.rails and self.rails != other.rails
        return false if self.db and other.db and self.db != other.db
        true
      end

      def match_any?(others)
        others.any?{|other| self.match? other}
      end

      def to_hash
        super.reject{ |k, val| val.nil? }
      end
    end

  end
end
