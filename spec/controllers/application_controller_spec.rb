require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe ApplicationController, type: :controller do
    controller do
      def index
        @time_zone = Time.zone

        render text: 'Time Zoned'
      end
    end

    describe "#with_time_zone" do
      let(:session_params) { {} }
      let(:expected_time_zone) { 'UTC' }

      before do
        get :index, {}, session_params
      end

      context "with a session present" do
        context "that contains a time zone" do
          let(:expected_time_zone) { 'America/Los_Angeles' }
          let(:session_params) { {'time_zone' => expected_time_zone} }

          it "sets the time zone correctly" do
            expect(assigns(:time_zone).name).to eq(expected_time_zone)
          end
        end

        context 'that does not contain a time zone' do
          let(:session_params) { {'user_id' => '42'} }

          it 'sets the time zone correctly' do
            expect(assigns(:time_zone).name).to eq(expected_time_zone)
          end
        end
      end

      context "with no session present" do
        it "sets the time zone correctly" do
          expect(assigns(:time_zone).name).to eq(expected_time_zone)
        end
      end
    end
  end
end
