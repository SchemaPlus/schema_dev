# frozen_string_literal: true

require 'pathname'
require 'which_works'

module SchemaDev
  module RubySelector
    def self.command(ruby)
      selector.command ruby
    end

    # for rspec, to avoid stickiness
    def self._reset
      @selector = nil
    end

    def self.selector
      @selector ||= [Chruby, Rvm, Rbenv].find(&:installed?)&.new || abort('No ruby version manager found')
    end

    class ManagerBase
      def self.installed?
        Which.which const_get :CORE_COMMAND
      end
    end

    class Chruby < ManagerBase
      CORE_COMMAND = 'chruby-exec'

      def initialize
        super

        @rubies = Pathname.new(ENV['HOME'])
                          .join('.rubies')
                          .entries
                          .map { |e| e.basename.to_s }
      end

      def command(ruby)
        bash = Which.which 'bash' || abort('no bash shell found')
        ruby = @rubies.select { |e| e =~ /^(ruby-)?#{ruby}(-p.*)?$/ }
                      .last || ruby
        "SHELL=#{bash} #{CORE_COMMAND} #{ruby} --"
      end
    end

    class Rvm < ManagerBase
      CORE_COMMAND = 'rvm'

      def command(ruby)
        "#{CORE_COMMAND} #{ruby} do"
      end
    end

    class Rbenv < ManagerBase
      CORE_COMMAND = 'rbenv'

      def initialize
        super

        # because we're running within a ruby program that was launched by
        # rbenv, we already have various environment variables set up.  need
        # strip those out so that the forked shell can run a diifferent ruby
        # version than the one we're in now.
        ENV['PATH'] = ENV['PATH'].split(':').reject { |dir| dir =~ %r{/\.?rbenv/(?!shims)} }.join(':')
        ENV['GEM_PATH'] = ENV['GEM_PATH'].split(':').reject { |dir| dir =~ %r{/\.?rbenv} }.join(':') unless ENV['GEM_PATH'].nil?
        ENV['RBENV_DIR'] = nil
        ENV['RBENV_HOOK_PATH'] = nil
        @versions ||= `rbenv versions --bare`.split
      end

      def command(ruby)
        version = @versions.select { |v| v.start_with? ruby }.last || abort("no ruby version '#{ruby}' installed in rbenv")
        "RBENV_VERSION=#{version}"
      end
    end
  end
end
