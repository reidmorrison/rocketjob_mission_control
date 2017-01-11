require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe ServersHelper, type: :helper do
    describe '#server_card_class' do
      context 'when the server is a zombie' do
        let(:server) { spy(zombie?: true) }

        it 'returns the correct class' do
          expect(helper.server_card_class(server)).to eq('callout-zombie')
        end
      end

    end
  end
end
