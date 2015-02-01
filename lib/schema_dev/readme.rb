require 'pathname'

module SchemaDev
  class Readme
    def self.update(config)
      new(config.matrix).update
    end

    attr_accessor :matrix, :readme

    def initialize(matrix)
      self.matrix = matrix
      self.readme = Pathname.new('README.md')
    end

    def update
      return false unless readme.exist?
      lines = readme.readlines
      newlines = sub_matrix(lines)
      if lines != newlines
        readme.write newlines.join
        return true
      end
    end

    def sub_matrix(lines)
      pattern = %r{^\s*<!-- SCHEMA_DEV: MATRIX}
      before = lines.take_while(&it !~ pattern)

      return lines if before == lines

      after = lines.reverse.take_while(&it !~ pattern).reverse

      contents = []
      contents << "<!-- SCHEMA_DEV: MATRIX - begin -->\n"
      contents << "<!-- These lines are auto-generated by schema_dev based on schema_dev.yml -->\n"
      self.matrix.group_by(&it.slice(:ruby, :activerecord)).each do |pair, items|
        contents << "* ruby **#{pair[:ruby]}** with activerecord **#{pair[:activerecord]}**, using #{items.map{|item| "**#{item[:db]}**"}.to_sentence(last_word_connector: ' or ')}\n"
      end
      contents << "\n"
      contents << "<!-- SCHEMA_DEV: MATRIX - end -->\n"

      before + contents + after
    end
  end
end
