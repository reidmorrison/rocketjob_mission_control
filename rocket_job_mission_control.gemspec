$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rocket_job_mission_control/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rocket_job_mission_control"
  s.version     = RocketJobMissionControl::VERSION
  s.authors     = ["Michael Cloutier", "Chris Lamb"]
  s.email       = [""]
  s.homepage    = "TODO"
  s.summary     = "Web UI for Rocket Job"
  s.description = "Adds a web interface for Rocket Job."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.1.9"
  s.add_dependency "bootstrap-sass", ">= 3.2.0.1"
  s.add_dependency "rubyzip"
  s.add_dependency "rocket_job"
end
