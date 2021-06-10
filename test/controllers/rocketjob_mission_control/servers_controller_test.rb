require_relative "../../test_helper"
require_relative "../../compare_hashes"

module RocketjobMissionControl
  class ServersControllerTest < ActionController::TestCase
    describe ServersController do
      before do
        set_role(:admin)
        RocketJob::Job.delete_all
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

      %i[stop pause resume].each do |server_action|
        describe "PATCH ##{server_action}" do
          describe "with a valid server id" do
            before do
              server.pause! if server_action == :resume
            end

            it "redirects to servers" do
              patch server_action, params: {id: server.id}
              assert_redirected_to servers_path
            end

            it "#{server_action} the server" do
              action = server_id = nil
              RocketJob::Subscribers::Server.stub(:publish, lambda { |_action, args|
                                                              action = _action
                                                              server_id = args[:server_id]
                                                            }) do
                patch server_action, params: {id: server.id}
              end
              assert_equal server_action, action
              assert_equal server.id, server_id
            end
          end
        end
      end

      describe "PATCH #update_all" do
        RocketjobMissionControl::ServersController::VALID_ACTIONS.each do |server_action, _action_message|
          describe "with '#{server_action}' as the server_action param" do
            before do
              patch :update_all, params: {server_action: server_action}
            end

            it "redirects to servers" do
              assert_redirected_to servers_path
            end

            it "does not display an error message" do
              assert_nil flash[:alert]
            end
          end
        end

        describe "with an invalid server_action param" do
          it "gets access denied" do
            assert_raises(AccessGranted::AccessDenied) do
              patch :update_all, params: {server_action: :bad_server_action}
            end
          end
        end
      end

      describe "DELETE #destroy" do
        describe "with a valid server id" do
          before do
            delete :destroy, params: {id: server.id}
          end

          it "redirects to servers" do
            assert_redirected_to servers_path
          end

          it "displays a flash message" do
            assert_equal I18n.t(:success, scope: %i[server destroy]), flash[:notice]
          end

          it "destroys the server" do
            refute RocketJob::Server.where(id: server.id).exists?
          end
        end

        describe "when the server is not found" do
          before do
            delete :destroy, params: {id: 999_999}
          end

          it "redirects to servers" do
            assert_redirected_to servers_path
          end

          it "displays a flash message" do
            assert_equal I18n.t(:failure, scope: %i[server find], id: 999_999), flash[:alert]
          end
        end
      end

      ([:index] + server_states).each do |state|
        describe "GET ##{state}" do
          describe "html" do
            describe "with no #{state} servers" do
              before do
                get state
              end

              it "succeeds" do
                assert_response :success
              end

              it "renders template" do
                assert_template :index
              end
            end

            describe "with #{state} servers" do
              before do
                one_server_for_every_state
                get state
              end

              it "succeeds" do
                assert_response :success
              end

              it "renders template" do
                assert_template :index
              end
            end
          end

          describe "json" do
            describe "with no #{state} server" do
              before do
                get state, format: :json
              end

              it "succeeds" do
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

              it "succeeds" do
                assert_response :success
                json          = JSON.parse(response.body)
                expected_data = {
                  starting: {
                    "0"           => /#{RocketJob::Server.starting.first.name}/,
                    "1"           => "0/10",
                    "2"           => /s ago/,
                    "3"           => /s ago/,
                    "4"           => %r{/servers/#{RocketJob::Server.starting.first.id}/stop},
                    "DT_RowClass" => "card callout callout-info"
                  },
                  running:  {
                    "0"           => /#{RocketJob::Server.running.first.name}/,
                    "1"           => "0/10",
                    "2"           => /s ago/,
                    "3"           => /s ago/,
                    "4"           => %r{/servers/#{RocketJob::Server.running.first.id}/stop},
                    "DT_RowClass" => "card callout callout-success"
                  },
                  paused:   {
                    "0"           => /#{RocketJob::Server.paused.first.name}/,
                    "1"           => "0/10",
                    "2"           => /s ago/,
                    "3"           => /s ago/,
                    "4"           => %r{/servers/#{RocketJob::Server.paused.first.id}/stop},
                    "DT_RowClass" => "card callout callout-warning"
                  },
                  stopping: {
                    "0"           => /#{RocketJob::Server.stopping.first.name}/,
                    "1"           => "0/10",
                    "2"           => /s ago/,
                    "3"           => /s ago/,
                    "4"           => %r{/servers/#{RocketJob::Server.stopping.first.id}},
                    "DT_RowClass" => "card callout callout-alert"
                  }
                }

                if state == :index
                  assert_equal 0, json["draw"]
                  assert_equal 4, json["recordsTotal"]
                  assert_equal 4, json["recordsFiltered"]
                  compare_array_of_hashes [expected_data[:starting], expected_data[:running], expected_data[:paused], expected_data[:stopping]], json["data"]
                else
                  assert_equal 0, json["draw"]
                  assert_equal 1, json["recordsTotal"]
                  assert_equal 1, json["recordsFiltered"]
                  compare_hash expected_data[state], json["data"].first
                end
              end
            end
          end
        end
      end

      describe "role base authentication control" do
        %i[index starting running paused stopping zombie].each do |method|
          it "#{method} has read access as default" do
            get method, format: :json
            assert_response :success
          end
        end

        %i[stop pause resume destroy].each do |method|
          describe method.to_s do
            before do
              server.pause! if method == :resume
            end

            %i[admin editor operator].each do |role|
              it "redirects with #{method} method and role #{role}" do
                set_role(role)
                patch method, params: {id: server.id}
                assert_response(:redirect)
              end
            end

            %i[manager dirmon user].each do |role|
              it "raises authentication error for #{role}" do
                set_role(role)
                assert_raises AccessGranted::AccessDenied do
                  patch method, params: {id: server.id}
                end
              end
            end
          end
        end

        RocketjobMissionControl::ServersController::VALID_ACTIONS.each do |server_action|
          describe "with '#{server_action}' as the server_action param" do
            %i[admin editor operator].each do |role|
              it "redirects to servers" do
                set_role(role)
                patch :update_all, params: {server_action: server_action}

                assert_response(:redirect)
              end
            end
          end
        end
      end
    end

    def set_role(r)
      Config.authorization_callback = lambda {
        {roles: [r]}
      }
    end
  end
end
