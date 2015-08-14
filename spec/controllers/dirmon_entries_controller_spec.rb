require 'rails_helper'

class FakeButGoodJob < RocketJob::Job

  def perform(id)
    id
  end
end

module RocketJobMissionControl
  RSpec.describe DirmonEntriesController do
    routes { Engine.routes }

    let(:dirmon_list) { spy(sort: []) }

    before do
      allow(RocketJob::DirmonEntry).to receive(:limit).and_return(dirmon_list)
    end

    describe 'GET #new' do
      before do
        get :new
      end

      it { expect(response.status).to eq(200) }

      it 'assigns a new entry' do
        expect(assigns(:dirmon_entry)).to be_present
        expect(assigns(:dirmon_entry)).to_not be_persisted
      end
    end

    describe 'POST #create' do
      context 'with valid parameters' do
        let(:dirmon_params) do
          {
            name: 'Test',
            path: '/files/',
            job_name: 'FakeButGoodJob',
            arguments: [ 42 ].to_json
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

        [:name, :path, :job_name].each do |attribute|
          it "assigns the correct value for #{attribute}" do
            expect(assigns(:dirmon_entry)[attribute]).to eq(dirmon_params[attribute])
          end
        end

        it 'persists arguments correctly' do
          expect(assigns(:dirmon_entry).arguments).to eq([42])
        end
      end

      context 'with invalid parameters' do
        let(:dirmon_params) do
          {
            name: 'Test',
            job_name: 'FakeAndBadJob',
            arguments: [ 42 ].to_json
          }
        end

        before do
          post :create, rocket_job_dirmon_entry: dirmon_params
        end

        it 'renders the new template' do
          expect(response.status).to eq(200)
          expect(response).to render_template(:new)
        end

        it 'has errors on the entry' do
          expect(assigns(:dirmon_entry)).to_not be_valid
        end

        it 'loads the other entries' do
          expect(dirmon_list).to have_received(:sort)
        end
      end
    end

    describe 'GET #edit' do
      before do
        @entry = RocketJob::DirmonEntry.create(
            name: 'Test',
            path: '/files/',
            job_name: 'FakeButGoodJob',
            arguments: [ 42 ]
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
      describe "with an invalid id" do
        before do
          allow(RocketJob::DirmonEntry).to receive(:find).and_return(nil)
          get :show, id: 42
        end

        it "redirects" do
          expect(response).to redirect_to(dirmon_entries_path)
        end

        it "adds a flash alert message" do
          expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:dirmon_entry, :find], id: 42))
        end
      end

      describe "with a valid id" do
        before do
          allow(RocketJob::DirmonEntry).to receive(:find).and_return('entry')
          get :show, id: 42
        end

        it "succeeds" do
          expect(response.status).to be(200)
        end

        it "assigns the entry" do
          expect(assigns(:dirmon_entry)).to be_present
        end

        it "assigns the entries" do
          expect(assigns(:dirmons)).to eq([])
        end

        it "grabs a sorted list" do
          expect(dirmon_list).to have_received(:sort).with(created_at: :desc)
        end
      end
    end

    describe 'GET #index' do
      describe "with no entries" do
        before do
          get :index
        end

        it "succeeds" do
          expect(response.status).to be(200)
        end

        it "grabs a sorted list of entries" do
          expect(dirmon_list).to have_received(:sort).with(created_at: :desc)
        end

        it "returns no entries" do
          expect(assigns(:dirmons)).to eq([])
        end
      end

      describe "with jobs" do
        let(:dirmon_list) { spy(sort: dirmons) }
        let(:dirmons) { ['fake_dirmon1', 'fake_dirmon2'] }

        describe "with no parameters" do
          before { get :index }

          it "succeeds" do
            expect(response.status).to be(200)
          end

          it "grabs a sorted list of entries" do
            expect(dirmon_list).to have_received(:sort).with(created_at: :desc)
          end

          it "returns the entries" do
            expect(assigns(:dirmons)).to match_array(dirmons)
          end
        end

        describe "with a state filter" do
          before { get :index, states: states}

          context "that is empty" do
            let(:states) { [] }

            it { expect(response.status).to be(200) }

            it "grabs a sorted list" do
              expect(dirmon_list).to have_received(:sort).with(created_at: :desc)
            end

            it "returns the entries" do
              expect(assigns(:dirmons)).to match_array(dirmons)
            end
          end

          context "with a state" do
            let(:query_spy) { spy(where: dirmons) }
            let(:dirmon_list) { spy(sort: query_spy) }
            let(:states) { ['enabled'] }

            it { expect(response.status).to be(200) }

            it "grabs a filtered list" do
              expect(query_spy).to have_received(:where).with(enabled: true)
            end

            it "returns the entries" do
              expect(assigns(:dirmons)).to match_array(dirmons)
            end
          end
        end
      end
    end
  end
end
