require 'pathname'
require 'which_works'

module SchemaDev
  module RubySelector
    def self.command(ruby)
      @@selector ||= [Chruby, Rvm, Rbenv].find(&:if_exists).andand.new || abort("No ruby version manager found")
      @@selector.command ruby
    end
    def self._reset # for rspec, to avoid stickiness
      @@selector = nil
    end

    class ManagerBase
      def self.if_exists
        Which.which const_get :CORE_COMMAND
      end
    end

    class Chruby < ManagerBase
      CORE_COMMAND = "chruby-exec"

      def initialize
        @rubies = Pathname.new(ENV['HOME']).join(".rubies").entries().map(&its.basename.to_s)
      end
      def command(ruby)
        bash = Which.which 'bash' || abort("no bash shell found")
        ruby = @rubies.select(&it =~ /^(ruby-)?#{ruby}(-p.*)?$/).last || ruby
        "SHELL=#{bash} #{CORE_COMMAND} #{ruby} --"
      end
    end

    class Rvm < ManagerBase
      CORE_COMMAND = "rvm"

      def command(ruby)
        "#{CORE_COMMAND} #{ruby} do"
      end
    end

    class Rbenv < ManagerBase
      CORE_COMMAND = "rbenv"

      def initialize
        # because we're running within a ruby program that was launched by
        # rbenv, we already have various environment variables set up.  need
        # strip those out so that the forked shell can run a diifferent ruby
        # version than the one we're in now.
        ENV['PATH'] = ENV['PATH'].split(':').reject{|dir| dir =~ %r{/\.?rbenv/(?!shims)}}.join(':')
        ENV['GEM_PATH'] = ENV['GEM_PATH'].split(':').reject{|dir| dir =~ %r{/\.?rbenv}}.join(':') unless ENV['GEM_PATH'].nil?
        ENV['RBENV_DIR'] = nil
        ENV['RBENV_HOOK_PATH'] = nil
        @versions ||= `rbenv versions --bare`.split
      end

      def command(ruby)
        version = @versions.select{|v| v.start_with? ruby}.last || abort("no ruby version '#{ruby}' installed in rbenv")
        "RBENV_VERSION=#{version}"
      end
    end

  end
end
