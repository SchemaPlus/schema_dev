# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schema_dev/version'

Gem::Specification.new do |spec|
  spec.name          = "schema_dev"
  spec.version       = SchemaDev::VERSION
  spec.authors       = ["ronen barzel"]
  spec.email         = ["ronen@barzel.org"]
  spec.summary       = %q{SchemaPlus development tools}
  spec.description   = %q{SchemaPlus development tools}
  spec.homepage      = "https://github.com/SchemaPlus/schema_dev"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "its-it"
  spec.add_dependency "key_struct"
  spec.add_dependency "thor"
  spec.add_dependency "fastandand"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
