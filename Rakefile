# Setup bundler to avoid having to run bundle exec all the time.
require 'rubygems'
require 'bundler/setup'

require 'rails/version'
rakefile     = Rails.version.to_f >= 5.2 ? '../rjmc/Rakefile' : '../rjmc4/Rakefile'
APP_RAKEFILE = File.expand_path(rakefile, __FILE__)
load 'rails/tasks/engine.rake'

require 'rake/testtask'
require_relative 'lib/rocket_job_mission_control/version'

task :gem do
  system 'gem build rocketjob_mission_control.gemspec'
end

task publish: :gem do
  system "git tag -a v#{RocketJobMissionControl::VERSION} -m 'Tagging #{RocketJobMissionControl::VERSION}'"
  system 'git push --tags'
  system "gem push rocketjob_mission_control-#{RocketJobMissionControl::VERSION}.gem"
  system "rm rocketjob_mission_control-#{RocketJobMissionControl::VERSION}.gem"
end

Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
  t.warning = false
end

# By default run tests against all appraisals
if !ENV["APPRAISAL_INITIALIZED"] && !ENV["TRAVIS"]
  require 'appraisal'
  task default: 'app:appraisal'
else
  task default: :test
end
