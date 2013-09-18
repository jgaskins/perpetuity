# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "perpetuity/version"

Gem::Specification.new do |s|
  s.name        = "perpetuity"
  s.version     = Perpetuity::VERSION
  s.authors     = ["Jamie Gaskins"]
  s.email       = ["jgaskins@gmail.com"]
  s.homepage    = "https://github.com/jgaskins/perpetuity"
  s.summary     = %q{Persistence library allowing serialization of Ruby objects}
  s.description = %q{Persistence layer for Ruby objects}
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 2.13"
  s.add_runtime_dependency "moped"
  s.add_runtime_dependency "pg"
end
