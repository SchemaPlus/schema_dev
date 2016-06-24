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

  gem.add_dependency "activesupport"
  gem.add_dependency "coveralls"
  gem.add_dependency "faraday"
  gem.add_dependency "fastandand"
  gem.add_dependency "hash_keyword_args"
  gem.add_dependency "its-it"
  gem.add_dependency "key_struct"
  gem.add_dependency "thor"
  gem.add_dependency "which_works"

  gem.add_development_dependency "bundler", "~> 1.7"
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency "rspec", "~> 3.0"
  gem.add_development_dependency "rspec-given"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "webmock"
end
