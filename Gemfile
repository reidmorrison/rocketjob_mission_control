source "https://rubygems.org"

gemspec

# Rocket Job 7.1 and IOStreams 2.2, which it requires, have not been released yet, so bundle them from their
# release branches, whose main branches are Rocket Job 8 and IOStreams 3.
# Remove once both are published to rubygems.org, which the gemspec already requires.
gem "iostreams", github: "reidmorrison/iostreams", branch: "v2"
gem "rocketjob", github: "reidmorrison/rocketjob", branch: "v7"

gem "minitest", "~> 5.0"
gem "mongoid", "~> 9.1.0"
gem "rails", "~> 8.1.0"
gem "sprockets-rails"

gem "appraisal"
gem "rake"
gem "rubyzip", platform: :ruby
gem "sprockets"

gem "capybara"
gem "cuprite"
gem "minispec-rails", require: false
gem "puma"
gem "rails-controller-testing"
gem "simplecov", require: false

gem "solargraph", require: false

gem "bundler-audit", require: false
gem "rubocop", require: false
gem "rubocop-capybara", require: false
gem "rubocop-minitest", require: false
gem "rubocop-performance", require: false
gem "rubocop-rails", require: false
gem "rubocop-rake", require: false
