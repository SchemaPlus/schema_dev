require 'pathname'

module SchemaDev

  module Gemfiles
    extend self

    TEMPLATES_ROOT = Pathname.new(__FILE__).dirname.parent.parent + "templates"

    def build(config)
      @src_root = TEMPLATES_ROOT
      @dst_root = Pathname.new('.')

      path = Pathname.new("gemfiles")

      _blow_away(path)

      _copy(path, 'Gemfile.base')

      config.rails.each do |rails|

        rails_path = path + "rails-#{rails}"
        _copy(rails_path, 'Gemfile.base')

        config.db.each do |db|
          _copy(rails_path, "Gemfile.#{db}")
        end
      end
    end

    def _copy(path, filename)
      srcfile = @src_root + path + filename
      dstfile = @dst_root + path + filename
      return unless srcfile.exist?

      dstfile.dirname.mkpath
      FileUtils.copy_file(srcfile, dstfile)
    end

    def _blow_away(path)
      (@dst_root + path).rmtree
    rescue Errno::ENOENT
    end
  end
end
