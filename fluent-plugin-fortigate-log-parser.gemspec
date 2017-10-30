# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-fortigate-log-parser"
  spec.version       = "0.2.1"
  spec.authors       = ["Yoshinori TERAOKA"]
  spec.email         = ["jyobijyoba@gmail.com"]
  spec.summary       = %q{fluentd plugin for parse FortiGate log}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/yteraoka/fluent-plugin-fortigate-log-parser"
  spec.license       = "MIT"
  spec.has_rdoc      = false

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "fluentd"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit", "~> 3.2"
end
