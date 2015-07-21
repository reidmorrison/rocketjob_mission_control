require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe WorkersController do
    routes { Engine.routes }

    [:stop, :pause, :resume].each do |worker_action|
      describe "PATCH ##{worker_action}" do
        describe "with a valid worker id" do
          let(:worker) { spy(id: 42, to_param: 42) }

          before do
            allow(RocketJob::Worker).to receive(:find).and_return(worker)
            patch worker_action, id: worker.id
          end

          it "redirects to workers" do
            expect(response).to redirect_to(workers_path)
          end

          it "displays a flash message" do
            expect(flash[:notice]).to eq(I18n.t(:success, scope: [:worker, worker_action]))
          end

          it "#{worker_action} the worker" do
            expect(worker).to have_received("#{worker_action}!".to_sym)
          end
        end

        describe "when the worker fails to #{worker_action}" do
          before do
            worker = spy("#{worker_action}!".to_sym => false)
            allow(RocketJob::Worker).to receive(:find).and_return(worker)
            patch worker_action, id: worker.id
          end

          it "redirects to workers" do
            expect(response).to redirect_to(workers_path)
          end

          it "displays a flash message" do
            expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:worker, worker_action]))
          end
        end
      end
    end

    describe "PATCH #update_all" do
      RocketJobMissionControl::WorkersController::VALID_STATES.each do |worker_action, action_message|
        context "with '#{worker_action}' as the worker_action param" do
          before do
            allow(RocketJob::Worker).to receive("#{worker_action}_all".to_sym)
            patch :update_all, worker_action: worker_action
          end

          it "redirects to workers" do
            expect(response).to redirect_to(workers_path)
          end
          it "displays a success message" do
            state_message = I18n.t(:success, scope: [:worker, :update_all], worker_action: action_message)
            expect(flash[:notice]).to eq(state_message)
          end
          it "does not display an error message" do
            expect(flash[:alert]).to be_nil
          end
        end
      end

      context "with an invalid worker_action param" do
        before do
          patch :update_all, worker_action: :bad_worker_action
        end

        it "redirects to workers" do
          expect(response).to redirect_to(workers_path)
        end
        it "does not display a success message" do
          expect(flash[:notice]).to be_nil
        end
        it "displays an error message" do
          expect(flash[:alert]).to eq(I18n.t(:invalid, scope: [:worker, :update_all]))
        end
      end
    end

    describe "DELETE #destroy" do
      describe "with a valid worker id" do
        let(:worker) { spy(id: 42, to_param: 42) }

        before do
          allow(RocketJob::Worker).to receive(:find).and_return(worker)
          delete :destroy, id: worker.id
        end

        it "redirects to workers" do
          expect(response).to redirect_to(workers_path)
        end

        it "displays a flash message" do
          expect(flash[:notice]).to eq(I18n.t(:success, scope: [:worker, :destroy]))
        end

        it "destroys the worker" do
          expect(worker).to have_received(:destroy)
        end
      end

      describe "when the worker fails to be destroyed" do
        before do
          worker = spy(destroy: false)
          allow(RocketJob::Worker).to receive(:find).and_return(worker)
          delete :destroy, id: worker.id
        end

        it "redirects to workers" do
          expect(response).to redirect_to(workers_path)
        end

        it "displays a flash message" do
          expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:worker, :destroy]))
        end
      end
    end
  end
end
