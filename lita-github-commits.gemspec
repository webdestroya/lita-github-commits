Gem::Specification.new do |spec|
  spec.name          = "lita-github-commits"
  spec.version       = "0.2.5"
  spec.authors       = ["Mitch Dempsey", "Steve Jernigan"]
  spec.email         = ["mrdempsey@gmail.com","steve.jernigan@gmail.com"]
  spec.description   = %q{A Lita handler that will display GitHub commit messages in the channel}
  spec.summary       = %q{A Lita handler that will display GitHub commit messages in the channel}
  spec.homepage      = "https://github.com/webdestroya/lita-github-commits"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 2.3", "< 5.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0.0.beta2"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"

  spec.metadata = { "lita_plugin_type" => "handler" }
end
