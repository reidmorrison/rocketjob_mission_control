APP_RAKEFILE = File.expand_path('../spec/dummy/Rakefile', __FILE__)
load 'rails/tasks/engine.rake'

require_relative 'lib/rocket_job_mission_control/version'
require 'rspec/core'
require 'rspec/core/rake_task'

task spec: 'app:spec'
task default: :spec

task :gem do
  system 'gem build rocketjob_mission_control.gemspec'
end

task publish: :gem do
  system "git tag -a v#{RocketJobMissionControl::VERSION} -m 'Tagging #{RocketJobMissionControl::VERSION}'"
  system 'git push --tags'
  system "gem push rocketjob_mission_control-#{RocketJobMissionControl::VERSION}.gem"
  system "rm rocketjob_mission_control-#{RocketJobMissionControl::VERSION}.gem"
end
