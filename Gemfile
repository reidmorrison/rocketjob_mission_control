source 'https://rubygems.org'

gemspec

gem 'rails', '~> 5.2.0'

gem 'rake'
gem 'minitest'
gem 'awesome_print'
gem 'rubyzip', platform: :ruby
gem 'appraisal'

# For high availability
gem 'mongo_ha', '~> 2.5.1'

group :test do
  gem 'rails-controller-testing'
  gem 'minispec-rails', require: false
end

# Rails 4.2
# gem 'minitest-rails'
#
gem 'iostreams', git: 'https://github.com/rocketjob/iostreams.git'
gem 'rocketjob', git: 'https://github.com/rocketjob/rocketjob.git', branch:'feature/batch'

group :development do
  gem 'rubocop'
  # For testing with local copies of the gems:
  # gem 'rails_semantic_logger', '>= 4.0.0', path: '../rails_semantic_logger'
  # gem 'rocketjob', path: '../rocketjob'
  # gem 'rocketjob_pro', path: '../rocketjob_pro'
  # gem 'mongoid', path: '../../mongoid'
end
