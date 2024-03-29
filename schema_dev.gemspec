# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schema_dev/version'

Gem::Specification.new do |gem|
  gem.name          = 'schema_dev'
  gem.version       = SchemaDev::VERSION
  gem.authors       = ['ronen barzel']
  gem.email         = ['ronen@barzel.org']
  gem.summary       = 'SchemaPlus development tools'
  gem.description   = 'SchemaPlus development tools'
  gem.homepage      = 'https://github.com/SchemaPlus/schema_dev'
  gem.license       = 'MIT'

  gem.files         = `git ls-files -z`.split("\x0")
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 2.5.0'

  gem.add_dependency 'activesupport', '>= 5.2', '< 7.1'
  gem.add_dependency 'faraday', '~> 1.0'
  gem.add_dependency 'simplecov'
  gem.add_dependency 'simplecov-lcov', '~> 0.8.0'
  gem.add_dependency 'thor', '>= 0.19', '< 2.0'
  gem.add_dependency 'which_works', '~> 1.0'

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rake', '~> 13.0'
  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'rspec-given', '~> 3.8'
  gem.add_development_dependency 'webmock', '~> 3.0'
end
