source 'https://rubygems.org'

gemspec

gem 'rails', '~> 5.2.0'

gem 'rake'
gem 'minitest'
gem 'awesome_print'
gem 'rubyzip', platform: :ruby
gem 'appraisal'

# For high availability
gem 'mongo_ha'

group :test do
  gem 'rails-controller-testing'
  gem 'minispec-rails', require: false
end

# Rails 4.2
# gem 'minitest-rails'

group :development do
  gem 'rubocop'
  # For testing with local copies of the gems:
  # gem 'rails_semantic_logger', path: '../rails_semantic_logger'
  # gem 'iostreams', path: '../iostreams'
  # gem 'rocketjob', path: '../rocketjob'
  # gem 'rocketjob_enterprise', path: '../rocketjob_enterprise'
end
