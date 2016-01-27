require_relative '../rails_helper'

class OneParamJob < RocketJob::Job
  def perform(id)
    id
  end
end

class NoParamsJob < RocketJob::Job
  def perform
    100_000
  end
end

module RocketJobMissionControl
  RSpec.describe DirmonEntriesController do
    routes { Engine.routes }

    let(:dirmon_list) { spy(sort: []) }

    before do
      allow(RocketJob::DirmonEntry).to receive(:limit).and_return(dirmon_list)
    end

    describe 'PATCH #enable' do
      before do
        patch :enable, id: existing_dirmon.id
      end

      let(:existing_dirmon) do
        RocketJob::DirmonEntry.create!(
          name:           'Test',
          job_class_name: 'OneParamJob',
          pattern:        'the_path',
          arguments:      ['42'],
          state:          starting_state,
        )
      end

      context 'when transition is allowed' do
        let(:starting_state) { 'pending' }

        it { expect(response).to redirect_to(dirmon_entry_path(existing_dirmon.id)) }

        it 'changes the state to enabled' do
          expect(existing_dirmon.reload.state).to eq(:enabled)
        end
      end

      context 'when transition is not allowed' do
        let(:starting_state) { 'enabled' }

        it { expect(response).to render_template(:show) }

        it 'alerts the user' do
          expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:dirmon_entry, :enable]))
        end
      end
    end

    describe 'PATCH #disable' do
      let(:existing_dirmon) do
        RocketJob::DirmonEntry.create!(
          name:           'Test',
          job_class_name: 'OneParamJob',
          pattern:        'the_path',
          arguments:      ['42'],
          state:          starting_state,
        )
      end

      before do
        patch :disable, id: existing_dirmon.id
      end

      context 'when transition is allowed' do
        let(:starting_state) { :enabled }

        it { expect(response).to redirect_to(dirmon_entry_path(existing_dirmon.id)) }

        it 'changes the state to disabled' do
          expect(existing_dirmon.reload.state).to eq(:disabled)
        end
      end

      context 'when transition is not allowed' do
        let(:starting_state) { :disabled }

        it { expect(response).to render_template(:show) }

        it 'alerts the user' do
          expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:dirmon_entry, :disable]))
        end
      end
    end

    describe 'GET #new' do
      let(:entry_params) { {} }

      before do
        get :new, entry_params
      end

      it { expect(response.status).to eq(200) }

      it 'assigns a new entry' do
        expect(assigns(:dirmon_entry)).to be_present
        expect(assigns(:dirmon_entry)).to_not be_persisted
      end

      context 'with form params' do
        let(:entry_params) { {rocket_job_dirmon_entry: {name: 'new entry'}} }

        it { expect(response.status).to eq(200) }

        it 'assigns the params to new entry' do
          expect(assigns(:dirmon_entry)).to be_present
          expect(assigns(:dirmon_entry).name).to eq('new entry')
        end

        context 'with a valid job_class_name' do
          let(:entry_params) { {rocket_job_dirmon_entry: {job_class_name: 'OneParamJob'}} }

          it { expect(response.status).to eq(200) }

          it 'assigns the job class' do
            expect(assigns(:dirmon_entry)).to be_present
            expect(assigns(:dirmon_entry).job_class).to eq(OneParamJob)
          end
        end

        context 'with an invalid job_class_name' do
          let(:entry_params) { {rocket_job_dirmon_entry: {job_class_name: 'BadJob'}} }

          it { expect(response.status).to eq(200) }

          it 'adds an error' do
            expect(assigns(:dirmon_entry)).to be_present
            expect(assigns(:dirmon_entry).errors[:job_class_name]).to be_present
          end
        end
      end

    end

    describe 'PATCH #update' do
      let(:existing_dirmon) do
        RocketJob::DirmonEntry.create!(
          name:           'Test',
          job_class_name: 'OneParamJob',
          pattern:        'the_path',
          arguments:      ['{"argument1":"value1", "argument2":"value2", "argument3":"value3"}']
        )
      end

      before do
        patch :update, id: existing_dirmon.id, rocket_job_dirmon_entry: dirmon_params
      end

      context 'with valid parameters' do
        let(:dirmon_params) do
          {
            pattern:        'the_path2',
            job_class_name: 'OneParamJob',
            arguments:      ['42']
          }
        end

        it 'redirects to the updated entry' do
          expect(response).to redirect_to(dirmon_entry_path(existing_dirmon))
        end

        it 'updates the entry' do
          expect(existing_dirmon.reload.pattern).to eq('the_path2')
        end

        it 'displays a success message' do
          expect(flash[:success]).to eq(I18n.t(:success, scope: [:dirmon_entry, :update]))
        end
      end

      context 'with invalid parameters' do
        let(:dirmon_params) do
          {
            job_class_name: 'FakeAndBadJob',
          }
        end

        it 'renders the edit template' do
          expect(response.status).to eq(200)
          expect(response).to render_template(:edit)
        end

        it 'has errors on the entry' do
          expect(assigns(:dirmon_entry)).to_not be_valid
        end

        context 'with invalid arguments json' do
          let(:dirmon_params) do
            {
              name:           'Test',
              job_class_name: 'OneParamJob',
              arguments:      [],
            }
          end

          it 'renders the new template' do
            expect(response.status).to eq(200)
            expect(response).to render_template(:edit)
          end

          it 'has errors on arguments' do
            expect(assigns(:dirmon_entry).errors[:arguments]).to be_present
          end
        end
      end
    end

    describe 'POST #create' do
      context 'with valid parameters' do

        [
          {job_class_name: 'OneParamJob', argument: ['42'], expected_value: [42]},
          {job_class_name: 'OneParamJob', argument: ['{"argument1":"value1", "argument2":"value2", "argument3":"value3"}'], expected_value: [{"argument1" => "value1", "argument2" => "value2", "argument3" => "value3"}]},
          {job_class_name: 'NoParamsJob', argument: [], expected_value: []}
        ].each do |arguments|
          context "and arguments are '#{arguments}'" do
            let(:dirmon_params) do
              {
                name:           'Test',
                pattern:        '/files/*',
                job_class_name: arguments[:job_class_name],
                arguments:      arguments[:argument],
                properties:     {description: '', priority: 42},
              }
            end

            before do
              post :create, rocket_job_dirmon_entry: dirmon_params
            end

            it 'creates the entry' do
              expect(assigns(:dirmon_entry)).to be_persisted
            end

            it 'has no errors' do
              expect(assigns(:dirmon_entry).errors.messages).to be_empty
            end

            it 'redirects to created entry' do
              expect(response).to redirect_to(dirmon_entry_path(assigns(:dirmon_entry)))
            end

            it 'does not load all entries' do
              expect(dirmon_list).to_not have_received(:sort)
            end

            it 'does not save blank properties' do
              expect(assigns(:dirmon_entry).properties[:description]).to eq(nil)
            end

            it 'saves properties' do
              expect(assigns(:dirmon_entry).properties[:priority]).to eq('42')
            end

            [:name, :pattern, :job_class_name].each do |attribute|
              it "assigns the correct value for #{attribute}" do
                expect(assigns(:dirmon_entry)[attribute]).to eq(dirmon_params[attribute])
              end
            end

            it 'persists arguments correctly' do
              expect(assigns(:dirmon_entry).arguments).to eq(arguments[:expected_value])
            end
          end
        end
      end

      context 'with invalid parameters' do
        let(:dirmon_params) do
          {
            name:           'Test',
            job_class_name: 'FakeAndBadJob',
            arguments:      [[42].to_json],
          }
        end

        before do
          post :create, rocket_job_dirmon_entry: dirmon_params
        end

        context 'on model attributes' do
          it 'renders the new template' do
            expect(response.status).to eq(200)
            expect(response).to render_template(:new)
          end

          it 'has errors on the entry' do
            expect(assigns(:dirmon_entry)).to_not be_valid
          end
        end

        context 'with invalid arguments json' do
          let(:dirmon_params) do
            {
              name:           'Test',
              job_class_name: 'OneParamJob',
              arguments:      ['{"bad" "json"}'],
            }
          end

          it 'renders the new template' do
            expect(response.status).to eq(200)
            expect(response).to render_template(:new)
          end

          it 'has errors on arguments' do
            expect(assigns(:dirmon_entry).errors[:arguments]).to be_present
          end
        end
      end
    end

    describe 'GET #edit' do
      before do
        @entry = RocketJob::DirmonEntry.create(
          name:           'Test',
          pattern:        '/files/',
          job_class_name: 'OneParamJob',
          arguments:      [42]
        )
        get :edit, id: @entry.id
      end

      it { expect(response.status).to eq(200) }

      it 'assigns the entry' do
        expect(assigns(:dirmon_entry)).to be_present
        expect(assigns(:dirmon_entry)).to eq(@entry)
      end
    end

    describe 'GET #show' do
      describe 'with an invalid id' do
        before do
          allow(RocketJob::DirmonEntry).to receive(:find).and_return(nil)
          get :show, id: 42
        end

        it 'redirects' do
          expect(response).to redirect_to(dirmon_entries_path)
        end

        it 'adds a flash alert message' do
          expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:dirmon_entry, :find], id: 42))
        end
      end

      describe 'with a valid id' do
        before do
          allow(RocketJob::DirmonEntry).to receive(:find).and_return('entry')
          get :show, id: 42
        end

        it 'succeeds' do
          expect(response.status).to be(200)
        end

        it 'assigns the entry' do
          expect(assigns(:dirmon_entry)).to be_present
        end
      end
    end

    describe 'DELETE #destroy' do
      let(:existing_dirmon) do
        RocketJob::DirmonEntry.create!(
          name:           'Test',
          job_class_name: 'OneParamJob',
          pattern:        'the_path',
          arguments:      [42].to_json
        )
      end

      describe 'with a valid id' do
        before { delete :destroy, id: existing_dirmon.id }

        it 'redirects to index' do
          expect(response).to redirect_to(dirmon_entries_path)
        end

        it 'displays a success message' do
          expect(flash[:success]).to eq(I18n.t(:success, scope: [:dirmon_entry, :destroy]))
        end

        it 'deletes the entry' do
          expect(RocketJob::DirmonEntry.find(existing_dirmon.id)).to eq(nil)
        end
      end
    end

    describe 'GET #index' do
      describe 'with no entries' do
        before do
          get :index
        end

        it 'succeeds' do
          expect(response.status).to be(200)
        end

        it 'grabs a sorted list of entries' do
          expect(dirmon_list).to have_received(:sort).with(created_at: :desc)
        end

        it 'returns no entries' do
          expect(assigns(:dirmons)).to eq([])
        end
      end

      describe 'with jobs' do
        let(:dirmon_list) { spy(sort: dirmons) }
        let(:dirmons) { ['fake_dirmon1', 'fake_dirmon2'] }

        describe 'with no parameters' do
          before { get :index }

          it 'succeeds' do
            expect(response.status).to be(200)
          end

          it 'grabs a sorted list of entries' do
            expect(dirmon_list).to have_received(:sort).with(created_at: :desc)
          end

          it 'returns the entries' do
            expect(assigns(:dirmons)).to match_array(dirmons)
          end
        end

        describe 'with a state filter' do
          before { get :index, states: states }

          context 'that is empty' do
            let(:states) { [] }

            it { expect(response.status).to be(200) }

            it 'grabs a sorted list' do
              expect(dirmon_list).to have_received(:sort).with(created_at: :desc)
            end

            it 'returns the entries' do
              expect(assigns(:dirmons)).to match_array(dirmons)
            end
          end

          context 'with a state' do
            let(:query_spy) { spy(where: dirmons) }
            let(:dirmon_list) { spy(sort: query_spy) }
            let(:states) { ['enabled'] }

            it { expect(response.status).to be(200) }

            it 'grabs a filtered list' do
              expect(query_spy).to have_received(:where).with(state: ['enabled'])
            end

            it 'returns the entries' do
              expect(assigns(:dirmons)).to match_array(dirmons)
            end
          end
        end
      end
    end
  end
end
