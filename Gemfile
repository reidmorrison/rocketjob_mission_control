source "https://rubygems.org"

gemspec

gem "rails", "~> 5.2.0"

gem "appraisal"
gem "awesome_print"
gem "minitest"
gem "rake"
gem "rubyzip", platform: :ruby
gem "sprockets", "< 4.0"

group :test do
  gem "minispec-rails", require: false
  gem "rails-controller-testing"
end

group :development do
  gem "rubocop"
  # For testing with local copies of the gems:
  # gem 'iostreams', path: '../iostreams'
  # gem "rocketjob", path: "../rocketjob"
end
