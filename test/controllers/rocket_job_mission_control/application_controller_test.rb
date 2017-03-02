require_relative '../../test_helper'

module RocketJobMissionControl
  class TestController < ApplicationController
    def index
      @time_zone = Time.zone

      render text: 'Time Zoned'
    end
  end

  class ApplicationControllerTest < ActionController::TestCase
    describe TestController do
      describe '#with_time_zone' do
        let(:session_params) { {} }
        let(:expected_time_zone) { 'UTC' }

        before do
          get :index, {}, session_params
        end

        describe 'with a session present' do
          describe 'that contains a time zone' do
            let(:expected_time_zone) { 'America/Los_Angeles' }
            let(:session_params) { {'time_zone' => expected_time_zone} }

            it 'sets the time zone correctly' do
              assert_equal expected_time_zone, assigns(:time_zone).name
            end
          end

          describe 'that does not contain a time zone' do
            let(:session_params) { {'user_id' => '42'} }

            it 'sets the time zone correctly' do
              assert_equal expected_time_zone, assigns(:time_zone).name
            end
          end
        end

        describe 'with no session present' do
          it 'sets the time zone correctly' do
            assert_equal expected_time_zone, assigns(:time_zone).name
          end
        end
      end
    end
  end
end
