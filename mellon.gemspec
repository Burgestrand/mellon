# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mellon/version"

Gem::Specification.new do |spec|
  spec.name          = "mellon"
  spec.version       = Mellon::VERSION
  spec.authors       = ["Kim Burgestrand"]
  spec.email         = ["kim@burgestrand.se"]
  spec.summary       = %q{A command-line utility for managing secret application credentials via OSX keychain.}
  spec.homepage      = "https://github.com/elabs/mellon"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "plist"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
