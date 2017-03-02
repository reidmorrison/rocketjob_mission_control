require_relative '../../test_helper'
require_relative '../../compare_hashes'

module RocketJobMissionControl
  class DirmonEntriesControllerTest < ActionController::TestCase

    describe DirmonEntriesController do
      before do
        RocketJob::DirmonEntry.delete_all
      end

      let :job_class_name do
        'RocketJob::Jobs::SimpleJob'
      end

      let :existing_dirmon_entry do
        RocketJob::DirmonEntry.create!(
          name:           'Test',
          job_class_name: job_class_name,
          pattern:        'the_path'
        )
      end

      dirmon_entry_states = RocketJob::DirmonEntry.aasm.states.collect(&:name)

      let :one_dirmon_entry_for_every_state do
        dirmon_entry_states.collect do |state|
          RocketJob::DirmonEntry.create!(
            name:           'Test',
            job_class_name: job_class_name,
            pattern:        'the_path',
            state:          state
          )
        end
      end

      describe 'PATCH #enable' do
        describe 'when transition is allowed' do
          before do
            patch :enable, id: existing_dirmon_entry.id
          end

          it do
            assert_redirected_to dirmon_entry_path(existing_dirmon_entry)
          end

          it 'changes the state to enabled' do
            assert existing_dirmon_entry.reload.enabled?
          end
        end

        describe 'when transition is not allowed' do
          before do
            existing_dirmon_entry.enable!
            patch :enable, id: existing_dirmon_entry.id
          end

          it 'succeeds' do
            assert_response :success
          end

          it 'alerts the user' do
            assert_equal I18n.t(:failure, scope: [:dirmon_entry, :enable]), flash[:alert]
          end
        end
      end

      describe 'PATCH #disable' do
        describe 'when transition is allowed' do
          before do
            existing_dirmon_entry.enable!
            patch :disable, id: existing_dirmon_entry.id
          end

          it do
            assert_redirected_to dirmon_entry_path(existing_dirmon_entry)
          end

          it 'changes the state to disabled' do
            assert existing_dirmon_entry.reload.disabled?
          end
        end

        describe 'when transition is not allowed' do
          before do
            patch :disable, id: existing_dirmon_entry.id
          end

          it 'succeeds' do
            assert_response :success
          end

          it 'alerts the user' do
            assert_equal I18n.t(:failure, scope: [:dirmon_entry, :disable]), flash[:alert]
          end
        end
      end

      describe 'GET #new' do
        let(:entry_params) { {} }

        before do
          get :new, entry_params
        end

        it 'succeeds' do
          assert_response :success
        end

        it 'assigns a new entry' do
          assert assigns(:dirmon_entry).present?
          refute assigns(:dirmon_entry).persisted?
        end

        describe 'with form params' do
          let(:entry_params) { {rocket_job_dirmon_entry: {name: 'new entry'}} }

          it 'succeeds' do
            assert_response :success
          end

          it 'assigns the params to new entry' do
            assert_equal 'new entry', assigns(:dirmon_entry).name
          end

          describe 'with a valid job_class_name' do
            let(:entry_params) { {rocket_job_dirmon_entry: {job_class_name: 'NoParamsJob'}} }

            it 'succeeds' do
              assert_response :success
            end

            it 'assigns the job class' do
              assert_equal 'NoParamsJob', assigns(:dirmon_entry).job_class_name
            end
          end

          describe 'with an invalid job_class_name' do
            let(:entry_params) { {rocket_job_dirmon_entry: {job_class_name: 'BadJob'}} }

            it 'succeeds' do
              assert_response :success
            end

            it 'adds an error' do
              assert assigns(:dirmon_entry).errors[:job_class_name].present?
            end
          end
        end

      end

      describe 'PATCH #update' do
        describe 'with valid parameters' do
          before do
            patch :update, id: existing_dirmon_entry.id, rocket_job_dirmon_entry: {pattern: 'the_path2', job_class_name: job_class_name}
          end

          it 'redirects to the updated entry' do
            assert_redirected_to dirmon_entry_path(existing_dirmon_entry)
          end

          it 'updates the entry' do
            #follow_redirect!
            #assert_equal 'the_path2', existing_dirmon_entry.reload.pattern
          end
        end

        describe 'with invalid parameters' do
          before do
            patch :update, id: existing_dirmon_entry.id, rocket_job_dirmon_entry: {job_class_name: 'FakeAndBadJob'}
          end

          it 'renders the edit template' do
            assert_redirected_to dirmon_entry_path(existing_dirmon_entry)
          end

          it 'alerts the user' do
            #follow_redirect!
            #assert_select 'div.message', "job_class_name: #{I18n.t(:failure, scope: [:dirmon_entry, :disable])}"
          end
        end
      end

      describe 'POST #create' do
        describe 'with valid parameters' do
          let(:dirmon_params) do
            {
              name:           'Test',
              pattern:        '/files/*',
              job_class_name: job_class_name,
              properties:     {description: '', priority: '42'}
            }
          end

          before do
            post :create, rocket_job_dirmon_entry: dirmon_params
          end

          it 'creates the entry' do
            assert assigns(:dirmon_entry).persisted?
          end

          it 'has no errors' do
            assert assigns(:dirmon_entry).errors.messages.empty?
          end

          it 'redirects to created entry' do
            assert_redirected_to dirmon_entry_path(assigns(:dirmon_entry))
          end

          it 'does not save blank properties' do
            assert_nil assigns(:dirmon_entry).properties[:description]
          end

          it 'saves properties' do
            assert_equal '42', assigns(:dirmon_entry).properties[:priority]
          end

          [:name, :pattern, :job_class_name].each do |attribute|
            it "assigns the correct value for #{attribute}" do
              assert_equal dirmon_params[attribute], assigns(:dirmon_entry)[attribute]
            end
          end
        end

        describe 'with invalid parameters' do
          let(:dirmon_params) do
            {
              name:           'Test',
              job_class_name: 'FakeAndBadJob'
            }
          end

          before do
            post :create, rocket_job_dirmon_entry: dirmon_params
          end

          describe 'on model attributes' do
            it 'renders the new template' do
              assert_response :success
              assert_template :new
            end

            it 'has errors on the entry' do
              refute assigns(:dirmon_entry).valid?
            end
          end
        end
      end

      describe 'GET #edit' do
        before do
          get :edit, id: existing_dirmon_entry.id
        end

        it 'succeeds' do
          assert_response :success
        end

        it 'assigns the entry' do
          assert_equal existing_dirmon_entry, assigns(:dirmon_entry)
        end
      end

      describe 'GET #show' do
        describe 'with an invalid id' do
          before do
            get :show, id: 42
          end

          it 'redirects' do
            assert_redirected_to dirmon_entries_path
          end

          it 'adds a flash alert message' do
            assert_equal I18n.t(:failure, scope: [:dirmon_entry, :find], id: 42), flash[:alert]
          end
        end

        describe 'with a valid id' do
          before do
            get :show, id: existing_dirmon_entry.id
          end

          it 'succeeds' do
            assert_response :success
          end

          it 'assigns the entry' do
            assert assigns(:dirmon_entry).present?
          end
        end
      end

      describe 'DELETE #destroy' do
        describe 'with a valid id' do
          before { delete :destroy, id: existing_dirmon_entry.id }

          it 'redirects to index' do
            assert_redirected_to dirmon_entries_path
          end

          it 'deletes the entry' do
            refute RocketJob::DirmonEntry.where(id: existing_dirmon_entry.id).exists?
          end
        end
      end

      ([:index] + dirmon_entry_states).each do |state|
        describe "GET ##{state}" do
          describe 'html' do
            describe "with no #{state} entries" do
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

            describe "with #{state} entries" do
              before do
                one_dirmon_entry_for_every_state
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
            describe "with #{state} entries" do
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

            describe "with #{state} entries" do
              before do
                one_dirmon_entry_for_every_state
                get state, format: :json
              end

              it 'succeeds' do
                assert_response :success
                json          = JSON.parse(response.body)
                expected_data = {
                  pending:  {
                    "0"           => "        <a href=\"/dirmon_entries/#{RocketJob::DirmonEntry.pending.first.id}\">\n          <i class=\"fa fa-inbox pending\" style=\"font-size: 75%\" title=\"pending\"></i>\n          Test\n        </a>\n",
                    "1"           => "RocketJob::Jobs::SimpleJob",
                    "2"           => "the_path",
                    "DT_RowClass" => "card callout callout-pending"
                  },
                  enabled:  {
                    "0"           => "        <a href=\"/dirmon_entries/#{RocketJob::DirmonEntry.enabled.first.id}\">\n          <i class=\"fa fa-check enabled\" style=\"font-size: 75%\" title=\"enabled\"></i>\n          Test\n        </a>\n",
                    "1"           => "RocketJob::Jobs::SimpleJob",
                    "2"           => "the_path",
                    "DT_RowClass" => "card callout callout-enabled"
                  },
                  failed:   {
                    "0"           => "        <a href=\"/dirmon_entries/#{RocketJob::DirmonEntry.failed.first.id}\">\n          <i class=\"fa fa-exclamation-triangle failed\" style=\"font-size: 75%\" title=\"failed\"></i>\n          Test\n        </a>\n",
                    "1"           => "RocketJob::Jobs::SimpleJob",
                    "2"           => "the_path",
                    "DT_RowClass" => "card callout callout-failed"
                  },
                  disabled: {
                    "0"           => "        <a href=\"/dirmon_entries/#{RocketJob::DirmonEntry.disabled.first.id}\">\n          <i class=\"fa fa-stop disabled\" style=\"font-size: 75%\" title=\"disabled\"></i>\n          Test\n        </a>\n",
                    "1"           => "RocketJob::Jobs::SimpleJob",
                    "2"           => "the_path",
                    "DT_RowClass" => "card callout callout-disabled"
                  }
                }

                if state == :index
                  assert_equal 0, json['draw']
                  assert_equal 4, json['recordsTotal']
                  assert_equal 4, json['recordsFiltered']
                  assert_equal [expected_data[:pending], expected_data[:enabled], expected_data[:failed], expected_data[:disabled]], json['data']
                else
                  assert_equal 0, json['draw']
                  assert_equal 1, json['recordsTotal']
                  assert_equal 1, json['recordsFiltered']
                  assert_equal [expected_data[state]], json['data']
                end
              end
            end
          end

        end
      end
    end
  end
end
