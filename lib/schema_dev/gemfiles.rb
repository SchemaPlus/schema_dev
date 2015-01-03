require 'pathname'

module SchemaDev

  module Gemfiles
    extend self

    TEMPLATES_ROOT = Pathname.new(__FILE__).dirname.parent.parent + "templates"

    def build(config)
      Dir.mktmpdir do |tmpdir|
        @src_root = TEMPLATES_ROOT
        @dst_root = Pathname.new(tmpdir).realpath

        relpath = Pathname.new("gemfiles")
        abspath = @dst_root + relpath
        target_abspath = Pathname.new(".").realpath + relpath

        _copy(relpath, 'Gemfile.base')

        config.rails.each do |rails|

          rails_path = relpath + "rails-#{rails}"
          _copy(rails_path, 'Gemfile.base')

          config.db.each do |db|
            _copy(rails_path, "Gemfile.#{db}")
          end
        end

        if `diff -rq #{abspath} gemfiles 2>&1 | grep -v lock`.length == 0
          return false
        end

        _blow_away(target_abspath)
        abspath.rename(target_abspath)
        return true
      end
    end

    def _copy(relpath, filename)
      srcfile = @src_root + relpath + filename
      dstfile = @dst_root + relpath + filename
      return unless srcfile.exist?

      dstfile.dirname.mkpath
      FileUtils.copy_file(srcfile, dstfile)
    end

    def _blow_away(relpath)
      (@dst_root + relpath).rmtree
    rescue Errno::ENOENT
    end
  end
end
