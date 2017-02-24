require_relative '../../test_helper'

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
          # expect(assigns(:dirmon_entry)).to be_present
          # expect(assigns(:dirmon_entry)).to_not be_persisted
        end

        describe 'with form params' do
          let(:entry_params) { {rocket_job_dirmon_entry: {name: 'new entry'}} }

          it 'succeeds' do
            assert_response :success
          end

          it 'assigns the params to new entry' do
            # expect(assigns(:dirmon_entry)).to be_present
            # expect(assigns(:dirmon_entry).name).to eq('new entry')
          end

          describe 'with a valid job_class_name' do
            let(:entry_params) { {rocket_job_dirmon_entry: {job_class_name: 'NoParamsJob'}} }

            it 'succeeds' do
              assert_response :success
            end

            it 'assigns the job class' do
              # expect(assigns(:dirmon_entry)).to be_present
              # expect(assigns(:dirmon_entry).job_class).to eq(NoParamsJob)
            end
          end

          describe 'with an invalid job_class_name' do
            let(:entry_params) { {rocket_job_dirmon_entry: {job_class_name: 'BadJob'}} }

            it 'succeeds' do
              assert_response :success
            end

            it 'adds an error' do
              # expect(assigns(:dirmon_entry)).to be_present
              # expect(assigns(:dirmon_entry).errors[:job_class_name]).to be_present
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
            #follow_redirect
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

          it 'does not load all entries' do
            #expect(dirmon_list).to_not have_received(:sort)
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
              #expect(response).to render_template(:new)
            end

            it 'has errors on the entry' do
              #expect(assigns(:dirmon_entry)).to_not be_valid
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
          # expect(assigns(:dirmon_entry)).to be_present
          # expect(assigns(:dirmon_entry)).to eq(@entry)
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

      describe 'GET #index' do
        describe 'html' do
          describe 'with no entries' do
            before do
              get :index
            end

            it 'succeeds' do
              assert_response :success
            end
          end

          describe 'with entries' do
            before do
              existing_dirmon_entry
              get :index
            end

            it 'succeeds' do
              assert_response :success
            end
          end
        end

        describe 'json' do
          describe 'with no entries' do
            before do
              get :index, format: :json
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

          describe 'with entries' do
            before do
              existing_dirmon_entry
              get :index, format: :json
            end

            it 'succeeds' do
              assert_response :success
              json     = JSON.parse(response.body)
              expected = {
                "data"            => [
                  {
                    "0"           => "        <a href=\"/dirmon_entries/#{existing_dirmon_entry.id}\">\n          <i class=\"fa fa-inbox pending\" style=\"font-size: 75%\" title=\"pending\"></i>\n          Test\n        </a>\n",
                    "1"           => "RocketJob::Jobs::SimpleJob",
                    "2"           => "the_path",
                    "DT_RowClass" => "card callout callout-pending"
                  }
                ],
                "draw"            => 0,
                "recordsFiltered" => 1,
                "recordsTotal"    => 1
              }
              assert_equal expected, json
            end
          end
        end

      end
    end
  end
end
