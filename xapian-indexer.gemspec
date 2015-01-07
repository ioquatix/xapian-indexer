# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xapian/indexer/version'

Gem::Specification.new do |spec|
	spec.name          = "xapian-indexer"
	spec.version       = Xapian::Indexer::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]
	spec.summary       = %q{Xapian::Indexer provides a flexible spider for indexing resources.}
	spec.homepage      = ""
	spec.license       = "MIT"

	spec.files         = `git ls-files -z`.split("\x0")
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]

	spec.add_dependency 'xapian-core', '~> 1.2.19.1'
	spec.add_dependency 'nokogiri'
	
	spec.add_development_dependency "bundler", "~> 1.6"
	spec.add_development_dependency "rake"
end
