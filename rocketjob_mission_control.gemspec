$:.push File.expand_path("lib", __dir__)

require "rocket_job_mission_control/version"

Gem::Specification.new do |s|
  s.name                  = "rocketjob_mission_control"
  s.version               = RocketJobMissionControl::VERSION
  s.authors               = ["Michael Cloutier", "Chris Lamb", "Jonathan Whittington", "Reid Morrison"]
  s.homepage              = "https://rocketjob.io"
  s.summary               = "Ruby's missing batch system."
  s.description           = "Rocket Job Mission Control is the Web user interface to manage Rocket Job."
  s.license               = "Apache-2.0"
  s.required_ruby_version = ">= 3.2"

  s.files = Dir["{app,config,db,lib,vendor}/**/*", "LICENSE.txt", "Rakefile", "README.md"]

  s.add_dependency "access-granted", "~> 1.3"
  s.add_dependency "railties", ">= 7.2"
  s.add_dependency "rocketjob", "~> 7.0"

  s.metadata = {
    "bug_tracker_uri"       => "https://github.com/reidmorrison/rocketjob_mission_control/issues",
    "changelog_uri"         => "https://github.com/reidmorrison/rocketjob_mission_control/blob/main/CHANGELOG.md",
    "documentation_uri"     => "https://rocketjob.io",
    "homepage_uri"          => "https://rocketjob.io",
    "source_code_uri"       => "https://github.com/reidmorrison/rocketjob_mission_control/tree/v#{RocketJobMissionControl::VERSION}",
    "rubygems_mfa_required" => "true"
  }
end
