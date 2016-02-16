require 'rails_helper'

module RocketJobMissionControl
  class ::TheJobClass < OpenStruct;
  end

  RSpec.describe JobsHelper, type: :helper do
    before do
      helper.extend(RocketJobMissionControl::ApplicationHelper)
    end

    describe '#job_action_link' do
      let(:action) { 'abort' }
      let(:http_method) { :patch }
      let(:path) { "/jobs/42/#{action}" }
      let(:action_link) { helper.job_action_link(action, path, http_method) }

      it 'uses the action as the label' do
        expect(action_link).to match(/>abort<\/a>/)
      end

      it 'links to the correct url' do
        expect(action_link).to match(/href="\/jobs\/42\/abort\"/)
      end

      it 'adds prompt for confirmation' do
        expect(action_link).to match(/data-confirm="Are you sure you want to abort this job\?"/)
      end

      it 'uses correct http method' do
        expect(action_link).to match(/data-method="patch"/)
      end
    end
  end
end
