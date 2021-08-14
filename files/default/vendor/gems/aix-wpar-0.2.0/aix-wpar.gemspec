$:.unshift(File.expand_path('lib', __dir__))
require 'wpars/version'

Gem::Specification.new do |gem|
  gem.authors       = ['Alain Dejoux']
  gem.email         = ['adejoux@djouxtech.net']
  gem.description   = %q(A wrapper for the AIX WPAR administration.)
  gem.license       = 'MIT'
  gem.summary       = %q(A ruby library wrapper for the AIX WPAR administration.)
  gem.homepage      = 'https://github.com/adejoux/aix-wpar'
  gem.files         = %w(LICENSE) + Dir.glob('*.gemspec') + Dir.glob('{lib,examples}/**/*')
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'aix-wpar'
  gem.require_paths = ['lib']
  gem.version       = WPAR::VERSION

  gem.add_dependency 'mixlib-shellout', ['> 2', '< 4']
end
