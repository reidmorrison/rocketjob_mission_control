require 'rails_helper'

describe RocketJobMissionControl::Jobs::Search do

  let(:search_term) { "bad[^$" }
  let(:expected_result) { [] }
  let(:search_subset) { spy("query_builder", where: expected_result) }

  subject { described_class.new(search_term, search_subset) }

  it 'escapes the search_term' do
    expect(subject.search_term).to eq('bad\\[\\^\\$')
  end

  describe '#execute' do
    before { subject.execute }

    describe 'with blank search terms' do
      let(:search_term) { "" }

      it 'does not search' do
        expect(search_subset).to_not have_received(:where)
      end
    end

    describe 'with search terms' do
      let(:search_term) { "job[" }

      it 'searches for the search term' do
        expect(search_subset).to have_received(:where).with({"$or"=>[{:_type=>/job\[/i}, {:description=>/job\[/i}]})
      end
    end
  end

end
