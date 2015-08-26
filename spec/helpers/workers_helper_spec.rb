require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe WorkersHelper, type: :helper do
    describe '#worker_card_class' do
      context 'when the worker is a zombie' do
        let(:worker) { spy(zombie?: true) }

        it 'returns the correct class' do
          expect(helper.worker_card_class(worker)).to eq('callout-zombie-top')
        end
      end

    end
  end
end
