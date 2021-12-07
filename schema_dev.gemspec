# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schema_dev/version'

Gem::Specification.new do |gem|
  gem.name          = "schema_dev"
  gem.version       = SchemaDev::VERSION
  gem.authors       = ["ronen barzel"]
  gem.email         = ["ronen@barzel.org"]
  gem.summary       = %q{SchemaPlus development tools}
  gem.description   = %q{SchemaPlus development tools}
  gem.homepage      = "https://github.com/SchemaPlus/schema_dev"
  gem.license       = "MIT"

  gem.files         = `git ls-files -z`.split("\x0")
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 2.5.0"

  gem.add_dependency "activesupport", ">= 5.2", "< 6.2"
  gem.add_dependency "coveralls_reborn", "~> 0.23"
  gem.add_dependency "faraday", "~> 0.9"
  gem.add_dependency "fastandand", "~> 1.0"
  gem.add_dependency "its-it", "~> 1.3"
  gem.add_dependency "key_struct", "~> 0.4"
  gem.add_dependency "thor", "~> 0.19"
  gem.add_dependency "which_works", "~> 1.0"

  gem.add_development_dependency "bundler"
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency "rspec", "~> 3.0"
  gem.add_development_dependency "rspec-given", "~> 3.8"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "webmock", "~> 2.1"
end
