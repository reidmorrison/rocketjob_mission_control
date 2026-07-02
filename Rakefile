# Setup bundler to avoid having to run bundle exec all the time.
require "rubygems"
require "bundler/setup"

require "rails/version"
APP_RAKEFILE = File.expand_path("rjmc/Rakefile", __dir__)
load "rails/tasks/engine.rake"

require "rake/testtask"
require "rubocop/rake_task"
require_relative "lib/rocket_job_mission_control/version"

RuboCop::RakeTask.new

task :gem do
  system "gem build rocketjob_mission_control.gemspec"
end

task publish: :gem do
  system "git tag -a v#{RocketJobMissionControl::VERSION} -m 'Tagging #{RocketJobMissionControl::VERSION}'"
  system "git push --tags"
  system "gem push rocketjob_mission_control-#{RocketJobMissionControl::VERSION}.gem"
  system "rm rocketjob_mission_control-#{RocketJobMissionControl::VERSION}.gem"
end

Rake::TestTask.new(:test) do |t|
  t.pattern = "test/**/*_test.rb"
  t.verbose = true
  t.warning = false
end

# By default run RuboCop once, then the tests against all appraisals.
# RuboCop is Rails/Ruby-version independent, so it runs at the top level rather
# than inside each appraisal.
if !ENV["APPRAISAL_INITIALIZED"] && !ENV["TRAVIS"]
  require "appraisal"
  task default: [:rubocop, "app:appraisal"]
else
  task default: :test
end
