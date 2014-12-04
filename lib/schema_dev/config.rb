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

    attr_accessor :quick, :db

    def self._reset ; @@config = nil end  # for use by rspec

    def self.load
      @@config ||= new((YAML.load Pathname.new(CONFIG_FILE).read).symbolize_keys)
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

    def initialize(opts={}) # once we no longer support ruby 1.9.3, can switch to native keyword args
      opts = opts.keyword_args(ruby: :required, rails: :required, db: nil, exclude: nil, notify: nil, quick: nil)
      @ruby = Array.wrap(opts.ruby)
      @rails = Array.wrap(opts.rails)
      @db = Array.wrap(opts.db)
      @exclude = Array.wrap(opts.exclude).map(&:symbolize_keys).map {|tuple| Tuple.new(tuple)}
      @notify = Array.wrap(opts.notify)
      @quick = Array.wrap(opts.quick || {ruby: @ruby.last, rails: @rails.last, db: @db.andand.last})
    end

    def db?
      @db.any?
    end

    def matrix(opts={}) # once we no longer support ruby 1.9.3, can switch to native keyword args
      opts = opts.keyword_args(quick: false, ruby: nil, rails: nil, db: nil)
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

      @matrix ||= begin
                    m = use_ruby.product(use_rails)
                    m = m.product(use_db).map(&:flatten) if db?
                    m = m.map { |_ruby, _rails, _db| Tuple.new(ruby: _ruby, rails: _rails, db: _db) }
                    m.reject(&it.match_any?(@exclude)).map(&:to_hash)
                  end
    end

  end
end
