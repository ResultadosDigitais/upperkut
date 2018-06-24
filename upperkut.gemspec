
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "upperkut/version"

Gem::Specification.new do |spec|
  spec.name          = "upperkut"
  spec.version       = Upperkut::VERSION
  spec.authors       = ["Nando Sousa"]
  spec.email         = ["nandosousafr@gmail.com"]

  spec.summary       = %q{Batch background processing tool}
  spec.description   = %q{Batch background processing tool}
  spec.homepage      = "http://shipit.resultadosdigitais.com.br/open-source/"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "all"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'redis'
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
