lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'upperkut/version'

Gem::Specification.new do |spec|
  spec.name          = 'upperkut'
  spec.version       = Upperkut::VERSION
  spec.authors       = ['Nando Sousa']
  spec.email         = ['nandosousafr@gmail.com']

  spec.summary       = 'Batch background processing tool'
  spec.description   = 'Batch background processing tool'
  spec.homepage      = 'http://shipit.resultadosdigitais.com.br/open-source/'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = ['upperkut']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'connection_pool', '~> 2.2', '>= 2.2.2'
  spec.add_dependency 'redis', '>= 4.1.0', '< 6.0.0'
  spec.add_development_dependency 'bundler', '>= 1.16'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
