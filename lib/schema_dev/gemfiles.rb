require 'pathname'

require_relative 'templates'

module SchemaDev

  module Gemfiles
    extend self

    def build(config)
      Dir.mktmpdir do |tmpdir|
        @src_root = Templates.root
        @dst_root = Pathname.new(tmpdir).realpath

        relpath = Pathname.new("gemfiles")
        abspath = @dst_root + relpath
        target_abspath = Pathname.new(".").realpath + relpath

        _copy(relpath, 'Gemfile.base')

        config.activerecord.each do |activerecord|

          activerecord_path = relpath + "activerecord-#{activerecord}"
          _copy(activerecord_path, 'Gemfile.base')

          config.db.each do |db|
            _copy(activerecord_path, "Gemfile.#{db}")
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
