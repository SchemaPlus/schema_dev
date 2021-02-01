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

    attr_accessor :quick, :db, :dbversions, :ruby, :activerecord, :notify, :exclude

    def self._reset ; @@config = nil end  # for use by rspec

    def self.read
      new((YAML.load Pathname.new(CONFIG_FILE).read).symbolize_keys)
    end

    def self.load
      @@config ||= read
    end

    def initialize(opts={}) # once we no longer support ruby 1.9.3, can switch to native keyword args
      opts = opts.keyword_args(ruby: :required, activerecord: :required, db: :required, dbversions: nil, exclude: nil, notify: nil, quick: nil)
      @ruby = Array.wrap(opts.ruby)
      @activerecord = Array.wrap(opts.activerecord)
      @db = Array.wrap(opts.db)
      @dbversions = (opts.dbversions || {}).symbolize_keys
      @exclude = Array.wrap(opts.exclude).map(&:symbolize_keys).map {|tuple| Tuple.new(tuple)}
      @notify = Array.wrap(opts.notify)
      @quick = Array.wrap(opts.quick || {ruby: @ruby.last, activerecord: @activerecord.last, db: @db.last})
    end

    def dbms
      @dbms ||= [:postgresql, :mysql].select{|dbm| @db.grep(/^#{dbm}/).any?}
    end

    def dbms_versions_for(db, default = [])
      @dbversions.fetch(db, default)
    end

    def matrix(opts={}) # once we no longer support ruby 1.9.3, can switch to native keyword args
      opts = opts.keyword_args(quick: false, ruby: nil, activerecord: nil, db: nil, excluded: nil)
      use_ruby = @ruby
      use_activerecord = @activerecord
      use_db = @db
      if opts.quick
        use_ruby = @quick.map{|q| q[:ruby]}
        use_activerecord = @quick.map{|q| q[:activerecord]}
        use_db = @quick.map{|q| q[:db]}
      end
      use_ruby = Array.wrap(opts.ruby) if opts.ruby
      use_activerecord = Array.wrap(opts.activerecord) if opts.activerecord
      use_db = Array.wrap(opts.db) if opts.db

      use_ruby = [nil] unless use_ruby.any?
      use_activerecord = [nil] unless use_activerecord.any?
      use_db = [nil] unless use_db.any?

      m = use_ruby.product(use_activerecord, use_db)
      m = m.map { |_ruby, _activerecord, _db| Tuple.new(ruby: _ruby, activerecord: _activerecord, db: _db) }.compact
      m = m.reject(&it.match_any?(@exclude)) unless opts.excluded == :none
      m = m.map(&:to_hash)

      if opts.excluded == :only
        return matrix(opts.merge(excluded: :none)) - m
      else
        return m
      end
    end

    class Tuple < KeyStruct[:ruby, :activerecord, :db]
      def match?(other)
        return false if self.ruby and other.ruby and self.ruby != other.ruby
        return false if self.activerecord and other.activerecord and self.activerecord != other.activerecord
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
