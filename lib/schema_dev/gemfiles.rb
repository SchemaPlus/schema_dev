require 'pathname'
require 'tmpdir'

require_relative 'templates'

module SchemaDev

  module Gemfiles
    extend self

    def build(config)
      Dir.mktmpdir do |tmpdir|
        @tmpdir = Pathname.new(tmpdir).realpath

        gemfiles = Pathname("gemfiles")
        tmp_root = @tmpdir + gemfiles
        target_root = Pathname.new(".").realpath + gemfiles

        _install gemfiles + 'Gemfile.base'

        config.activerecord.each do |activerecord|
          activerecord_path = gemfiles + "activerecord-#{activerecord}"
          _install activerecord_path + 'Gemfile.base'
          config.db.each do |db|
            _install  activerecord_path + "Gemfile.#{db}"
          end
        end

        if `diff -rq #{tmp_root} #{target_root} 2>&1 | grep -v lock`.length == 0
          return false
        end

        _force_rename(tmp_root, target_root)
        return true
      end
    end

    def _install(relpath)
      Templates.install_relative src: relpath, dst: @tmpdir
    end

    def _force_rename(src, dst)
      dst.rmtree if dst.directory?
      src.rename dst
    end
  end
end
