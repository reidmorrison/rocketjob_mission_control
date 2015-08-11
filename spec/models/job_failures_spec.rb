require 'rails_helper'

RSpec.describe JobFailures do
  describe '#job' do
    before do
      allow(RocketJob::Job).to receive(:find)
    end

    it 'looks up the job' do
      described_class.new(42).job
      expect(RocketJob::Job).to have_received(:find).with(42)
    end
  end
end
