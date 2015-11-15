require 'pathname'
require 'which_works'

module SchemaDev
  module RubySelector
    def self.command(ruby)
      @@selector ||= nil
      if @@selector.nil?
        managers = [ ['chruby-exec', Chruby],
                     ['rvm', Rvm],
                     ['rbenv', Rbenv]
                   ]
        sel = managers.find { |cmd,kls| Which.which(cmd) }
        if sel
          @@selector = sel[1].new
        else
          abort("no ruby version manager (#{ managers.collect{|mgr|mgr[0]}.join(', ') }) found")
        end
      end
      @@selector.command ruby
    end
    def self._reset # for rspec, to avoid stickiness
      @@selector = nil
    end

    class Chruby
      def initialize
        @rubies = Pathname.new(ENV['HOME']).join(".rubies").entries().map(&its.basename.to_s)
      end
      def command(ruby)
        bash = Which.which 'bash'
        abort("no bash shell found") if bash.nil?
        ruby = @rubies.select(&it =~ /^(ruby-)?#{ruby}(-p.*)?$/).last || ruby
        "SHELL=\"#{bash}\" chruby-exec #{ruby} --"
      end
    end

    class Rvm
      def command(ruby)
        "rvm #{ruby} do"
      end
    end

    class Rbenv
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
