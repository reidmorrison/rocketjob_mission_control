require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe SlicesHelper, type: :helper do
    before do
      helper.extend(RocketJobMissionControl::ApplicationHelper)
    end

    describe '#display_slice_info' do
      let(:slice) { {id: 42, name: 'test'} }

      context "when encrypted" do
        it { expect(helper.display_slice_info(slice, true)).to eq('encrypted') }
      end

      context "when unencrypted" do
        before do
          allow(helper).to receive(:pretty_print_array_or_hash)
        end

        it "does not return 'encrypted'" do
          expect(helper.display_slice_info(slice, false)).to_not eq('encrypted')
        end

        it "displays the slice info" do
          helper.display_slice_info(slice, false)
          expect(helper).to have_received(:pretty_print_array_or_hash).with(slice.to_a)
        end
      end

    end
  end
end
