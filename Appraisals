appraise "rails_7.2" do
  gem "rails", "~> 7.2.0"
  gem "mongoid", "~> 8.1.0"
  # Rails 7.2 and 8.0 pass quirks_mode to JSON.generate, which json 3 rejects.
  gem "json", "< 3"
end

appraise "rails_8.0" do
  gem "rails", "~> 8.0.0"
  gem "mongoid", "~> 9.0.0"
  # Rails 7.2 and 8.0 pass quirks_mode to JSON.generate, which json 3 rejects.
  gem "json", "< 3"
end

appraise "rails_8.1" do
  gem "rails", "~> 8.1.0"
  gem "mongoid", "~> 9.1.0"
end
