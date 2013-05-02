# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dotted_hash/version'

Gem::Specification.new do |spec|
  spec.name          = "dotted_hash"
  spec.version       = DottedHash::VERSION
  spec.authors       = ["Ivan Stana"]
  spec.email         = ["stiipa@centrum.sk"]
  spec.description   = %q{Recursive OpenStruct-like or Hash-like object. Based on Tire::Result::Item with addition of writing attributes and security limits.}
  spec.summary       = %q{Recursive OpenStruct-like object.}
  spec.homepage      = "http://github.com/istana/dotted_hash"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.extra_rdoc_files  = [ "README.md", "MIT-LICENSE" ]
  spec.rdoc_options      = [ "--charset=UTF-8" ]
  
  spec.add_dependency "activemodel", ">= 3.0"
  spec.add_dependency "activesupport"
  
  unless defined?(JRUBY_VERSION)
    spec.add_development_dependency "turn"
  end

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
	spec.add_development_dependency "rspec", "~> 2.13"
end
