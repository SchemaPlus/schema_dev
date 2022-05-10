# frozen_string_literal: true

require 'active_support/core_ext/hash'
require 'pathname'
require 'yaml'
require 'rubygems/version'

module SchemaDev
  CONFIG_FILE = 'schema_dev.yml'

  class Config
    attr_accessor :quick, :db, :dbversions, :ruby, :activerecord, :exclude

    # for use by rspec
    def self._reset
      @load = nil
    end

    def self.read
      if ::Gem::Version.new(RUBY_VERSION) >= ::Gem::Version.new('3.1')
        new(**YAML.safe_load(Pathname.new(CONFIG_FILE).read, permitted_classes: [Symbol], symbolize_names: true))
      else
        new(**YAML.safe_load(Pathname.new(CONFIG_FILE).read, [Symbol], symbolize_names: true))
      end
    end

    def self.load
      @load ||= read
    end

    def initialize(ruby:, activerecord:, db:, dbversions: nil, exclude: nil, notify: nil, quick: nil)
      @ruby = Array.wrap(ruby).map(&:to_s)
      @activerecord = Array.wrap(activerecord).map(&:to_s)
      @db = Array.wrap(db)
      @dbversions = (dbversions || {}).symbolize_keys
      @exclude = Array.wrap(exclude).map(&:symbolize_keys).map { |tuple| Tuple.new(**tuple.transform_values(&:to_s)) }
      @activerecord.each do |ar_version|
        ar_check = Gem::Version.new(ar_version)

        if ar_check < Gem::Version.new('6.0')
          ruby3 = ::Gem::Version.new('3.0')

          @ruby.select { |e| ::Gem::Version.new(e) >= ruby3 }.each do |v|
            @exclude << Tuple.new(ruby: v, activerecord: ar_version)
          end
        elsif ar_check >= Gem::Version.new('7.0')
          ruby27 = ::Gem::Version.new('2.7')

          @ruby.select { |e| ::Gem::Version.new(e) < ruby27 }.each do |v|
            @exclude << Tuple.new(ruby: v, activerecord: ar_version)
          end
        end
      end
      unless notify.nil?
        warn 'Notify is no longer supported'
      end
      @quick = Array.wrap(quick || { ruby: @ruby.last, activerecord: @activerecord.last, db: @db.last })
    end

    def dbms
      @dbms ||= %i[postgresql mysql].select { |dbm| @db.grep(/^#{dbm}/).any? }
    end

    DB_VERSION_DEFAULTS = {
      postgresql: ['9.6']
    }.freeze

    def db_versions_for(db)
      @dbversions.fetch(db.to_sym, DB_VERSION_DEFAULTS.fetch(db.to_sym, [])).map(&:to_s)
    end

    def matrix(quick: false, ruby: nil, activerecord: nil, db: nil, excluded: nil, with_dbversion: false)
      use_ruby = @ruby
      use_activerecord = @activerecord
      use_db = @db
      if quick
        use_ruby = @quick.map { |q| q[:ruby] }
        use_activerecord = @quick.map { |q| q[:activerecord] }
        use_db = @quick.map { |q| q[:db] }
      end
      use_ruby = Array.wrap(ruby) if ruby
      use_activerecord = Array.wrap(activerecord) if activerecord
      use_db = Array.wrap(db) if db

      use_ruby = [nil] unless use_ruby.any?
      use_activerecord = [nil] unless use_activerecord.any?
      use_db = [nil] unless use_db.any?

      m = use_ruby.product(use_activerecord, use_db)
      m = m.flat_map do |loop_ruby, loop_activerecord, loop_db|
        if with_dbversion && !(dbversions = db_versions_for(loop_db)).empty?
          dbversions.map { |v| Tuple.new(ruby: loop_ruby, activerecord: loop_activerecord, db: loop_db, dbversion: v) }
        else
          [Tuple.new(ruby: loop_ruby, activerecord: loop_activerecord, db: loop_db)]
        end
      end.compact
      m = m.reject { |r| r.match_any?(@exclude) } unless excluded == :none
      m = m.map(&:to_hash)

      if excluded == :only
        matrix(quick: quick, ruby: ruby, activerecord: activerecord, db: db, with_dbversion: with_dbversion, excluded: :none) - m
      else
        m
      end
    end

    Tuple = Struct.new(:ruby, :activerecord, :db, :dbversion, keyword_init: true) do
      def match?(other)
        return false if ruby and other.ruby and ruby != other.ruby
        return false if activerecord and other.activerecord and activerecord != other.activerecord
        return false if db and other.db and db != other.db
        return false if dbversion and other.dbversion and dbversion != other.dbversion

        true
      end

      def match_any?(others)
        others.any? { |other| match? other }
      end

      def to_hash
        to_h.compact.transform_values(&:to_s)
      end
    end
  end
end
