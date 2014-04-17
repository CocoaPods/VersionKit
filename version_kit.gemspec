# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version_kit/gem_metadata'

Gem::Specification.new do |spec|
  spec.name          = 'version_kit'
  spec.version       = VersionKit::VERSION
  spec.authors       =  ['Fabio Pelosin']
  spec.email         =  ['fabiopelosin@gmail.com']
  spec.summary       = %q(Provides support for SemVer versions and dependency resolution)
  spec.homepage      = 'https://github.com/CocoaPods/VersionKit'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb'] + %w(README.md LICENSE)
  spec.test_files    = Dir['spec/**/*.rb']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
end
