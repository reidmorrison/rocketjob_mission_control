appraise "rails_7.2" do
  gem "rails", "~> 7.2.0"
  gem "mongoid", "~> 8.1.0"
  # Rails 7.2 and 8.0 pass quirks_mode to JSON.generate, which json 3 rejects.
  gem "json", "< 3"
  # Rails 7.2's test runner (line_filtering) only supports Minitest 5, which has stub and Mock built in, so it does
  # not need the minitest-mock gem.
  gem "minitest", "~> 5.0"
  remove_gem "minitest-mock"
end

appraise "rails_8.0" do
  # Rails 8.0.5 is the first 8.0 release whose test runner supports Minitest 6.
  gem "rails", "~> 8.0.5"
  gem "mongoid", "~> 9.0.0"
  # Rails 7.2 and 8.0 pass quirks_mode to JSON.generate, which json 3 rejects.
  gem "json", "< 3"
end

appraise "rails_8.1" do
  # Rails 8.1.2 is the first 8.1 release whose test runner supports Minitest 6.
  gem "rails", "~> 8.1.2"
  gem "mongoid", "~> 9.1.0"
end
