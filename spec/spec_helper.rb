require 'simplecov'
SimpleCov.start

require 'tmpdir'

require 'schema_dev/config'

def in_tmpdir
  Dir.mktmpdir do |dir|
    Dir.chdir(dir) do
      yield
    end
  end
end

def get_config(data)
  SchemaDev::Config._reset
  in_tmpdir do
    Pathname.new(SchemaDev::CONFIG_FILE).open("w") {|f| f.write data.to_yaml }
    SchemaDev::Config.load
  end
end
