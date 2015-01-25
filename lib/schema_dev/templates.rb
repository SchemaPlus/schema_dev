require 'pathname'

module SchemaDev
  module Templates
    def self.root
      @root ||= Pathname.new(__FILE__).dirname.parent.parent + "templates"
    end
  end
end
