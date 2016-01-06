require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe Jobs::FailuresController do
    routes { Engine.routes }

    describe "GET #index" do
      describe "with a failed job" do
        let(:job) { spy(failed?: true, id: 42) }
        let(:slice_errors) do
          [
            {
              '_id'     =>
                {
                  'error_class' => 'BoomError',
                },
              'message' => ['boom'],
              'count'   => '1337',
            },
          ]
        end
        let(:selected_exception) { spy(count: 1337, first: current_failure) }
        let(:current_failure) { {'exception' => 'Doh! Something blew up!'} }

        before do
          allow(RocketJob::Job).to receive(:find).and_return(job)
          allow(job).to receive_message_chain('input.collection.aggregate') { slice_errors }
          allow(job).to receive_message_chain('input.collection.find.limit') { selected_exception }
          get :index, job_id: job.id
        end

        context 'with slice errors' do
          it 'succeeds' do
            expect(response).to be_success
          end
          it 'returns the job' do
            expect(assigns(:job)).to eq(job)
          end
          it 'returns the errors' do
            expect(assigns(:slice_errors)).to eq(slice_errors)
          end
          it 'returns the first exception' do
            expect(assigns(:failure_exception)).to eq(current_failure['exception'])
          end
        end

        context 'with no slice errors' do
          let(:slice_errors) { [] }

          it 'succeeds' do
            expect(response).to be_success
          end
          it 'returns the job' do
            expect(assigns(:job)).to eq(job)
          end
          it 'returns no errors' do
            expect(assigns(:slice_errors)).to eq(slice_errors)
          end
          it 'returns no exception' do
            expect(assigns(:failure_exception)).to be_nil
          end
          it 'notifies the user' do
            expect(flash[:notice]).to eq(I18n.t(:no_errors, scope: [:job, :failures]))
          end
        end
      end

      describe "with a job that is not failed" do
        let(:job) { spy(failed?: false, id: 42) }

        before do
          allow(RocketJob::Job).to receive(:find).and_return(job)
          get :index, job_id: job.id
        end

        it "redirects to the job" do
          expect(response).to redirect_to(job_path(job.id))
        end
      end
    end
  end
end
