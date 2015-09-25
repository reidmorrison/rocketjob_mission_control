$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'rocket_job_mission_control/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'rocketjob_mission_control'
  s.version     = RocketJobMissionControl::VERSION
  s.authors     = ['Michael Cloutier', 'Chris Lamb']
  s.email       = ['']
  s.homepage    = 'https://github.com/mjcloutier/rocket_job_mission_control'
  s.summary     = 'Mission Control is the Web user interface to manage rocketjob jobs'
  s.description = 'Rails Engine for adding the web interface for rocketjob to Rails apps'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib,vendor}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.markdown']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'rails', '~> 4.0'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'bootstrap-sass', '>= 3.2.0.1'
  s.add_dependency 'coffee-rails'
  s.add_dependency 'selectize-rails'
  s.add_dependency 'sass-rails', '>=3.2'
  s.add_dependency 'rocketjob', '~> 1.1'
  s.add_dependency 'mongo_ha'
  s.add_dependency 'mongo', '~>1.0'
  s.add_dependency 'mongo_mapper', '~> 0.13'
  s.add_dependency 'haml'
end
