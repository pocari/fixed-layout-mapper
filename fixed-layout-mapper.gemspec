# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fixed-layout-mapper/version"

Gem::Specification.new do |s|
  s.name        = "fixed-layout-mapper"
  s.version     = FixedLayoutMapper::VERSION
  s.authors     = ["pocari"]
  s.email       = ["caffelattenonsugar@gmail.com"]
  s.homepage    = "https://github.com/pocari"
  s.summary     = %q{Mapping fixed layout record to ruby's Struct or Array object.}
  s.description = ""

  s.rubyforge_project = "fixed-layout-mapper"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
