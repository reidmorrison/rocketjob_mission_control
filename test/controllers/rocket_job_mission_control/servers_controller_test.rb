require_relative '../../test_helper'

module RocketJobMissionControl
  class ServersControllerTest < ActionController::TestCase
    describe ServersController do

      before do
        RocketJob::Server.delete_all
      end

      let :server do
        s = RocketJob::Server.new
        s.started!
        s
      end

      server_states = RocketJob::Server.aasm.states.collect(&:name)

      let :one_server_for_every_state do
        server_states.collect do |state|
          server = RocketJob::Server.new(state: state)
          server.build_heartbeat(updated_at: Time.now, workers: 0)
          server.save!
        end
      end

      [:stop, :pause, :resume].each do |server_action|
        describe "PATCH ##{server_action}" do
          describe 'with a valid server id' do
            before do
              server.pause! if server_action == :resume
              patch server_action, id: server.id
            end

            it 'redirects to servers' do
              assert_redirected_to servers_path
            end

            it "#{server_action} the server" do
              results = {stop: :stopping?, pause: :paused?, resume: :running?}
              assert server.reload.send(results[server_action])
            end
          end

          describe "when the server fails to #{server_action}" do
            before do
              server.pause! if server_action == :pause
              server.stop! if server_action == :stop
              patch server_action, id: server.id
            end

            it 'redirects to servers' do
              assert_redirected_to servers_path
            end

            it 'displays a flash message' do
              assert_equal I18n.t(:failure, scope: [:server, server_action]), flash[:alert]
            end
          end
        end
      end

      describe 'PATCH #update_all' do
        RocketJobMissionControl::ServersController::VALID_ACTIONS.each do |server_action, action_message|
          describe "with '#{server_action}' as the server_action param" do
            before do
              patch :update_all, server_action: server_action
            end

            it 'redirects to servers' do
              assert_redirected_to servers_path
            end

            it 'does not display an error message' do
              assert_nil flash[:alert]
            end
          end
        end

        describe 'with an invalid server_action param' do
          before do
            patch :update_all, server_action: :bad_server_action
          end

          it 'redirects to servers' do
            assert_redirected_to servers_path
          end

          it "does not display a success message" do
            assert_nil flash[:notice]
          end

          it 'displays an error message' do
            assert_equal I18n.t(:invalid, scope: [:server, :update_all]), flash[:alert]
          end
        end
      end

      describe 'DELETE #destroy' do
        describe 'with a valid server id' do
          before do
            delete :destroy, id: server.id
          end

          it 'redirects to servers' do
            assert_redirected_to servers_path
          end

          it 'displays a flash message' do
            assert_equal I18n.t(:success, scope: [:server, :destroy]), flash[:notice]
          end

          it 'destroys the server' do
            refute RocketJob::Server.where(id: server.id).exists?
          end
        end

        describe 'when the server is not found' do
          before do
            delete :destroy, id: 999999
          end

          it 'redirects to servers' do
            assert_redirected_to servers_path
          end

          it 'displays a flash message' do
            assert_equal I18n.t(:failure, scope: [:server, :find], id: 999999), flash[:alert]
          end
        end
      end

      ([:index] + server_states).each do |state|
        describe "GET ##{state}" do
          describe 'html' do
            describe "with no #{state} servers" do
              before do
                get state
              end

              it 'succeeds' do
                assert_response :success
              end

              it 'renders template' do
                assert_template :index
              end
            end

            describe "with #{state} servers" do
              before do
                one_server_for_every_state
                get state
              end

              it 'succeeds' do
                assert_response :success
              end

              it 'renders template' do
                assert_template :index
              end
            end
          end

          describe 'json' do
            describe "with no #{state} server" do
              before do
                get state, format: :json
              end

              it 'succeeds' do
                assert_response :success
                json     = JSON.parse(response.body)
                expected = {
                  "data"            => [],
                  "draw"            => 0,
                  "recordsFiltered" => 0,
                  "recordsTotal"    => 0
                }
                assert_equal expected, json
              end
            end

            describe "with #{state} server" do
              before do
                one_server_for_every_state
                get state, format: :json
              end

              it 'succeeds' do
                assert_response :success
                json = JSON.parse(response.body)
                expected_data = {
                  starting: {
                    "0"           => /#{RocketJob::Server.starting.first.name}/,
                    "1"           => "0/10",
                    "2"           => /s ago/,
                    "3"           => /s ago/,
                    "4"           => /\/servers\/#{RocketJob::Server.starting.first.id}\/stop/,
                    "DT_RowClass" => "card callout callout-info"
                  },
                  running:  {
                    "0"           => /#{RocketJob::Server.running.first.name}/,
                    "1"           => "0/10",
                    "2"           => /s ago/,
                    "3"           => /s ago/,
                    "4"           => /\/servers\/#{RocketJob::Server.running.first.id}\/stop/,
                    "DT_RowClass" => "card callout callout-success"
                  },
                  paused:   {
                    "0"           => /#{RocketJob::Server.paused.first.name}/,
                    "1"           => "0/10",
                    "2"           => /s ago/,
                    "3"           => /s ago/,
                    "4"           => /\/servers\/#{RocketJob::Server.paused.first.id}\/stop/,
                    "DT_RowClass" => "card callout callout-warning"
                  },
                  stopping: {
                    "0"           => /#{RocketJob::Server.stopping.first.name}/,
                    "1"           => "0/10",
                    "2"           => /s ago/,
                    "3"           => /s ago/,
                    "4"           => /\/servers\/#{RocketJob::Server.stopping.first.id}/,
                    "DT_RowClass" => "card callout callout-alert"
                  }
                }

                if state == :index
                  assert_equal 0, json['draw']
                  assert_equal 4, json['recordsTotal']
                  assert_equal 4, json['recordsFiltered']
                  compare_array_of_hashes [expected_data[:starting], expected_data[:running], expected_data[:paused], expected_data[:stopping]], json['data']
                else
                  assert_equal 0, json['draw']
                  assert_equal 1, json['recordsTotal']
                  assert_equal 1, json['recordsFiltered']
                  compare_hash expected_data[state], json['data'].first
                end
              end
            end
          end

        end
      end

      def compare_array_of_hashes(expected, actual)
        expected.each_with_index do |expected_hash, index|
          compare_hash(expected_hash, actual[index])
        end
      end

      def compare_hash(expected_hash, actual_hash)
        expected_hash.each_pair do |key, expected|
          actual = actual_hash[key]
          if expected.is_a?(Regexp)
            assert_match expected, actual, "#{key} does not match. Expected #{expected.inspect}. Actual #{actual.inspect}"
          else
            assert_equal expected, actual, "#{key} not equal. Expected #{expected.inspect}. Actual #{actual.inspect}"
          end
        end
      end

    end
  end
end
