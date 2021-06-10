# Setup bundler to avoid having to run bundle exec all the time.
require "rubygems"
require "bundler/setup"

require "rails/version"
APP_RAKEFILE = File.expand_path("../rjmc/Rakefile", __FILE__)
load "rails/tasks/engine.rake"

require "rake/testtask"
require_relative "lib/rocketjob_mission_control/version"

task :gem do
  system "gem build rocketjob_mission_control.gemspec"
end

task publish: :gem do
  system "git tag -a v#{RocketjobMissionControl::VERSION} -m 'Tagging #{RocketjobMissionControl::VERSION}'"
  system "git push --tags"
  system "gem push rocketjob_mission_control-#{RocketjobMissionControl::VERSION}.gem"
  system "rm rocketjob_mission_control-#{RocketjobMissionControl::VERSION}.gem"
end

Rake::TestTask.new(:test) do |t|
  t.pattern = "test/**/*_test.rb"
  t.verbose = true
  t.warning = false
end

# By default run tests against all appraisals
if !ENV["APPRAISAL_INITIALIZED"] && !ENV["TRAVIS"]
  require "appraisal"
  task default: "app:appraisal"
else
  task default: :test
end

load "lib/tasks/rocketjob_mission_control_tasks.rake"
