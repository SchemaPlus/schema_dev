require 'faraday'
require 'fileutils'
require 'pathname'
require 'active_support/core_ext/string'

require_relative 'templates'

module SchemaDev
  class Gem
    def self.build(name)
      new(name).build
    end

    attr_accessor :gem_name, :gem_module, :gem_root, :fullname, :email

    def initialize(name)
      self.gem_name = name.underscore
      self.gem_module = gem_name.camelize
      self.gem_root = Pathname.new(gem_name)
    end

    def build
      ensure_not_in_git
      ensure_doesnt_exist
      get_fullname_and_email
      copy_template
      self.gem_root = self.gem_root.realpath
      rename_files
      substitute_keys
      freshen
      git_init
      puts <<-END.strip_heredoc

         Created #{gem_name}.  Your recommended next steps are:

                $ cd #{gem_name}
                $ bundle install
                $ schema_dev bundle install
                $ schema_dev rspec
      END
    end

    def die(msg)
      abort "schema_dev: #{msg}"
    end

    def ensure_not_in_git
      if system("git rev-parse >& /dev/null")
        die "Cannot create new gem inside existing git worktree; please cd elsewhere"
      end
    end

    def ensure_doesnt_exist
      if gem_root.exist?
        die "Cannot create new gem: '#{gem_root}' already exists"
      end
    end

    def get_fullname_and_email
      {'fullname' => 'name', 'email' => 'email' }.each do |myattr, gitattr|
        if (self.send myattr+"=", `git config user.#{gitattr}`.strip).blank?
          die "Who are you?  Please run 'git config --global user.#{gitattr} <your-#{gitattr}>'"
        end
      end
    end

    def copy_template
      FileUtils.cp_r Templates.root + "gem", gem_root
    end

    def rename_files
      Dir.glob(gem_root + "**/*GEM_NAME*").each do |path|
        FileUtils.mv path, path.gsub(/GEM_NAME/, gem_name)
      end
    end

    def substitute_keys
      gem_root.find.each do |path|
        next unless path.file?
        path.write subs(path.read)
      end
    end

    def subs(s)
      s = s.gsub('%GEM_NAME%', gem_name)
      s = s.gsub('%GEM_MODULE%', gem_module)
      s = s.gsub('%FULLNAME%', fullname)
      s = s.gsub('%EMAIL%', email)
      s = s.gsub('%SCHEMA_MONKEY_DEPENDENCY%', dependency(schema_monkey_version))
      s = s.gsub('%SCHEMA_DEV_DEPENDENCY%', dependency(SchemaDev::VERSION))
      s = s.gsub('%YEAR%', Time.now.strftime("%Y"))
    end

    def dependency(v)
      major, minor, patch = v.split('.')
      dep = %Q{"~> #{major}.#{minor}"}
      dep += %Q{, ">= #{v}"} if patch != "0"
      dep
    end

    def schema_monkey_version
      @monkey_version ||= begin
                            gems = JSON.parse Faraday.get('https://rubygems.org/api/v1/versions/schema_money.json').body
                            gems.reject(&it["prerelease"]).sort_by{|g| Time.new(g["built_at"])}.last["number"]
                          end
    end

    def freshen
      Dir.chdir gem_root do 
        Runner.new(Config.read).freshen(quiet=true)
      end
    end

    def git_init
      Dir.chdir gem_name do 
        system "git init"
        system "git add #{gem_root.find.select(&:exist?).join(' ')}"
        system "git commit -m 'Initial skeleton generated by `schema_dev gem #{gem_name}`'"
      end
    end
  end
end
