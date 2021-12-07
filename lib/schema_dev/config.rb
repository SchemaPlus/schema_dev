require 'active_support/core_ext/hash'
require 'enumerator'
require 'its-it'
require 'key_struct'
require 'pathname'
require 'yaml'

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

    def initialize(ruby:, activerecord:, db:, dbversions: nil, exclude: nil, notify: nil, quick: nil)
      @ruby = Array.wrap(ruby)
      @activerecord = Array.wrap(activerecord)
      @db = Array.wrap(db)
      @dbversions = (dbversions || {}).symbolize_keys
      @exclude = Array.wrap(exclude).map(&:symbolize_keys).map {|tuple| Tuple.new(tuple)}
      @notify = Array.wrap(notify)
      @quick = Array.wrap(quick || {ruby: @ruby.last, activerecord: @activerecord.last, db: @db.last})
    end

    def dbms
      @dbms ||= [:postgresql, :mysql].select{|dbm| @db.grep(/^#{dbm}/).any?}
    end

    def dbms_versions_for(db, default = [])
      @dbversions.fetch(db, default)
    end

    def matrix(quick: false, ruby: nil, activerecord: nil, db: nil, excluded: nil)
      use_ruby = @ruby
      use_activerecord = @activerecord
      use_db = @db
      if quick
        use_ruby = @quick.map{|q| q[:ruby]}
        use_activerecord = @quick.map{|q| q[:activerecord]}
        use_db = @quick.map{|q| q[:db]}
      end
      use_ruby = Array.wrap(ruby) if ruby
      use_activerecord = Array.wrap(activerecord) if activerecord
      use_db = Array.wrap(db) if db

      use_ruby = [nil] unless use_ruby.any?
      use_activerecord = [nil] unless use_activerecord.any?
      use_db = [nil] unless use_db.any?

      m = use_ruby.product(use_activerecord, use_db)
      m = m.map { |_ruby, _activerecord, _db| Tuple.new(ruby: _ruby, activerecord: _activerecord, db: _db) }.compact
      m = m.reject(&it.match_any?(@exclude)) unless excluded == :none
      m = m.map(&:to_hash)

      if excluded == :only
        matrix(quick: quick, ruby: ruby, activerecord: activerecord, db: db, excluded: :none) - m
      else
        m
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
