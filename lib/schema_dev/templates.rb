require 'pathname'

module SchemaDev
  module Templates
    def self.root
      @root ||= Pathname.new(__FILE__).dirname.parent.parent + "templates"
    end

    def self.install_subtree(src:, dst:, bound: nil)
      src = root + src
      Pathname.glob(src + "**/*").select(&:file?).each do |p|
        _install(p, dst + p.relative_path_from(src).sub_ext(''), bound)
      end
    end

    def self.install_relative(src:, dst:, bound: nil)
      srcfile = root + src
      dstfile = dst + src
      _install(srcfile, dstfile, bound)
    end

    def self._install(src, dst, bound)
      src = Pathname(src.to_s + ".erb") unless src.file?
      dst.sub_ext '' if dst.extname == '.erb'
      dst.dirname.mkpath
      dst.write process(src.read, bound: bound)
    end

    def self.process(text, bound: nil)
      ERB.new(text).result(bound)
    end


  end
end
