# frozen_string_literal: true

require 'simplecov'
SimpleCov.start unless SimpleCov.running

require 'rspec/given'
require 'tempfile'
require 'tmpdir'
require 'webmock/rspec'

require 'schema_dev/config'

def in_tmpdir(&block)
  Dir.mktmpdir do |dir|
    Dir.chdir(dir, &block)
  end
end

def suppress_stdout_stderr
  save_stdout = STDOUT.dup
  save_stderr = STDERR.dup
  begin
    Tempfile.open do |f|
      STDOUT.reopen f
      STDERR.reopen f
      yield
    end
  ensure
    STDERR.reopen save_stderr
    STDOUT.reopen save_stdout
  end
end

def get_config(data)
  SchemaDev::Config._reset
  in_tmpdir do
    Pathname.new(SchemaDev::CONFIG_FILE).open('w') { |f| f.write data.to_yaml }
    SchemaDev::Config.load
  end
end
