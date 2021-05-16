source "https://rubygems.org"

gemspec

gem "rails", "~> 6.1.0"
gem "mongoid", git: "https://github.com/reidmorrison/mongoid", branch:"7.2-ruby_3"
gem "rocketjob", path: "../rocketjob"
gem "appraisal"
gem "amazing_print"
gem "minitest"
gem "rake"
gem "rubyzip", platform: :ruby
gem "sprockets"

group :test do
  gem "minispec-rails", require: false
  gem "rails-controller-testing"
end

group :development do
  gem 'rubocop', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
end
