# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in schema_dev.gemspec
gemspec

gemfile_local = File.expand_path '../Gemfile.local', __FILE__
eval File.read(gemfile_local), binding, gemfile_local if File.exist? gemfile_local
