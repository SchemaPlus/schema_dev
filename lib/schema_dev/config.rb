require 'active_support/core_ext/hash'
require 'enumerator'
require 'fastandand'
require 'its-it'
require 'key_struct'
require 'pathname'
require 'yaml'

module SchemaDev
  CONFIG_FILE = "schema_dev.yml"

  class Config

    attr_accessor :quick

    def self.load
      new (YAML.load Pathname.new(CONFIG_FILE).read).deep_symbolize_keys
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

    def initialize(ruby:, rails:, db: nil, exclude: nil, notify: nil, quick: nil)
      @ruby = Array.wrap(ruby)
      @rails = Array.wrap(rails)
      @db = Array.wrap(db)
      @exclude = Array.wrap(exclude).map(&:symbolize_keys).map {|tuple| Tuple.new(tuple)}
      @notify = Array.wrap(notify)
      @quick = Array.wrap(quick || {ruby: @ruby.last, rails: @rails.last, db: @db.andand.last})
    end

    def db?
      @db.any?
    end

    def matrix(quick: false, ruby: nil, rails: nil, db: nil)
      use_ruby = @ruby
      use_rails = @rails
      use_db = @db
      if quick
        use_ruby = @quick.map{|q| q[:ruby]}
        use_rails = @quick.map{|q| q[:rails]}
        use_db = @quick.map{|q| q[:db]}
      end
      use_ruby = Array.wrap(ruby) if ruby
      use_rails = Array.wrap(rails) if rails
      use_db = Array.wrap(db) if db

      @matrix ||= begin
                    m = use_ruby.product(use_rails)
                    m = m.product(use_db).map(&:flatten) if db?
                    m = m.map { |_ruby, _rails, _db| Tuple.new(ruby: _ruby, rails: _rails, db: _db) }
                    m.reject(&it.match_any?(@exclude)).map(&:to_hash)
                  end
    end

  end
end
