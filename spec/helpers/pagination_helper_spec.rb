require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe PaginationHelper, type: :helper do
    describe '#page_nav_disabled_class' do

      context 'when the current position equals the boundary' do
        it 'returns disabled' do
          expect(helper.page_nav_disabled_class(0, 0)).to eq('disabled')
        end
      end

      context 'when the current position is NOT equal to the boundary' do
        it 'returns blank' do
          expect(helper.page_nav_disabled_class(4, 0)).to be_blank
        end
      end

    end
  end
end
