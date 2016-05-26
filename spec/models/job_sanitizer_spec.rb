require 'rails_helper'

RSpec.describe JobSanitizer do
  describe '#sanitize' do
    it "replaces blank string in log_level with nil" do
      params = { job: { log_level: '' } }
      sanitized = { job: { log_level: nil } }
      expect(JobSanitizer.new(params).sanitize).to eq(sanitized)
    end

    it "leaves valid log_levels alone" do
      params = { job: { log_level: :warn } }
      expect(JobSanitizer.new(params).sanitize).to eq(params)
    end
  end
end
