lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docl/version'

Gem::Specification.new do |gem|
    gem.name = "docl"
    gem.version = DOCL::VERSION
    gem.authors = ["Nathan Samson"]
    gem.email = ["nathan@nathansamson.be"]
    gem.license = "MIT"
    gem.description = %q{A command line tool for interacting with your DigitalOcean droplets.}
    gem.summary = %q{A command line tool for interacting with your DigitalOcean droplets.}
    gem.homepage = "https://github.com/nathansamson/docl"

    gem.files = `git ls-files`.split($/)
    gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
    gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
    gem.require_paths = ["lib"]
    gem.required_ruby_version = ">= 1.9.3"

    gem.add_dependency "thor", "~> 0.19.1"
    gem.add_dependency "barge", "~> 0.10.0"
    gem.add_dependency "json", "~> 1.8.1"
end