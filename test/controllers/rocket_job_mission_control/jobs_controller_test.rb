require_relative '../../test_helper'
require_relative '../../compare_hashes'

module RocketJobMissionControl
  class JobsControllerTest < ActionController::TestCase

    class PausableJob < RocketJob::Job
      self.pausable = true

      def perform
        21
      end
    end

    describe JobsController do
      before do
        set_role(:admin)
        RocketJob::Job.delete_all
      end

      let :job do
        RocketJob::Jobs::SimpleJob.create!
      end

      let :pausable_job do
        PausableJob.create!
      end

      let :failed_job do
        job = KaboomBatchJob.new(slice_size: 1)
        job.upload do |stream|
          stream << 'first record'
          stream << 'second record'
          stream << 'third record'
        end
        job.save!

        # Run all 3 slices now to get exceptions for each.
        3.times do
          begin
            job.perform_now
          rescue ArgumentError, RuntimeError
          end
        end
        job
      end

      job_states = RocketJob::Job.aasm.states.collect(&:name)

      let :one_job_for_every_state do
        job_states.collect do |state|
          RocketJob::Jobs::SimpleJob.create!(state: state, worker_name: 'worker', started_at: (Time.now - 0.5))
        end
      end

      [:pause, :resume, :abort, :retry, :fail].each do |state|
        describe "PATCH ##{state}" do
          describe 'with an invalid job id' do
            before do
              params = {id: 42, job: {id: 42, priority: 12}}
              params = {params: params} if Rails.version.to_i >= 5
              patch state, params
            end

            it 'redirects' do
              assert_redirected_to jobs_path
            end

            it 'adds a flash alert message' do
              assert_equal I18n.t(:failure, scope: [:job, :find], id: 42), flash[:alert]
            end
          end

          describe 'with a valid job id' do
            before do
              case state
              when :pause, :fail, :abort
                pausable_job.start!
              when :resume
                pausable_job.pause!
              when :retry
                pausable_job.fail!
              end
              params = {id: pausable_job.id, job: {id: pausable_job.id, priority: pausable_job.priority}}
              params = {params: params} if Rails.version.to_i >= 5
              patch state, params
            end

            it 'redirects to the job' do
              assert_redirected_to job_path(pausable_job.id)
            end

            it 'transitions the job' do
              refute_equal state, pausable_job.state
            end
          end
        end
      end

      describe 'PATCH #run_now' do
        let(:scheduled_job) { RocketJob::Jobs::SimpleJob.create!(run_at: 2.days.from_now) }

        before do
          params = {id: scheduled_job.id}
          params = {params: params} if Rails.version.to_i >= 5
          patch :run_now, params
        end

        it 'redirects to the job path' do
          assert_redirected_to job_path(scheduled_job.id)
        end

        it 'updates run_at' do
          assert_nil scheduled_job.reload.run_at
        end
      end


      describe "PATCH #update" do
        describe 'with an invalid job id' do
          before do
            params = {id: 42, job: {id: 42, priority: 12}}
            params = {params: params} if Rails.version.to_i >= 5
            patch :update, params
          end

          it 'redirects' do
            assert_redirected_to jobs_path
          end

          it 'adds a flash alert message' do
            assert_equal I18n.t(:failure, scope: [:job, :find], id: 42), flash[:alert]
          end
        end

        describe "with a valid job id" do
          before do
            params = {id: job.id, job: {id: job.id, priority: 12, blah: 23, description: '', log_level: '', state: 'failed'}}
            params = {params: params} if Rails.version.to_i >= 5
            patch :update, params
          end

          it 'redirects to the job' do
            assert_redirected_to job_path(job.id)
          end

          it 'updates the job correctly' do
            assert_equal 12, job.reload.priority
          end

          it "calls sanitize" do
            job.reload
            assert_nil job.description
            assert_nil job.log_level
            assert_equal :queued, job.state
          end
        end
      end

      describe 'GET #show' do
        describe 'with an invalid job id' do
          before do
            params = {id: 42}
            params = {params: params} if Rails.version.to_i >= 5
            get :show, params
          end

          it 'redirects' do
            assert_redirected_to jobs_path
          end

          it 'adds a flash alert message' do
            assert_equal I18n.t(:failure, scope: [:job, :find], id: 42), flash[:alert]
          end
        end

        describe "with a valid job id" do
          before do
            params = {id: job.id}
            params = {params: params} if Rails.version.to_i >= 5
            get :show, params
          end

          it 'succeeds' do
            assert_response :success
          end

          it 'assigns the job' do
            assert_equal job.id, assigns(:job).id
          end
        end
      end

      describe 'GET #exception' do
        describe 'with an invalid job id' do
          before do
            params = {id: 42}
            params = {params: params} if Rails.version.to_i >= 5
            get :exception, params
          end

          it 'redirects' do
            assert_redirected_to jobs_path
          end

          it 'adds a flash alert message' do
            assert_equal I18n.t(:failure, scope: [:job, :find], id: 42), flash[:alert]
          end
        end

        describe 'with a valid job id' do
          describe 'without an exception' do
            before do
              params = {id: failed_job.id, error_type: 'Blah'}
              params = {params: params} if Rails.version.to_i >= 5
              get :exception, params
            end

            it 'redirects to job path' do
              assert_redirected_to job_path(failed_job.id)
            end

            it 'notifies the user' do
              assert_equal I18n.t(:no_errors, scope: [:job, :failures]), flash[:notice]
            end
          end

          describe 'with exception' do
            before do
              params = {id: failed_job.id, error_type: 'ArgumentError'}
              params = {params: params} if Rails.version.to_i >= 5
              get :exception, params
            end

            it 'succeeds' do
              assert_response :success
            end

            it 'assigns the job' do
              assert_equal failed_job.id, assigns(:job).id
            end

            it 'paginates' do
              assert_equal 0, assigns(:pagination)[:offset], assigns(:pagination)
              assert_equal 1, assigns(:pagination)[:total], assigns(:pagination)
            end

            it 'returns the first exception' do
              assert_equal 'ArgumentError', assigns(:failure_exception).class_name
              assert_equal 'Blowing up on record: 1', assigns(:failure_exception).message
              assert assigns(:failure_exception).backtrace.present?
            end
          end
        end
      end

      ([:index] + job_states).each do |state|
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
                one_job_for_every_state
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
                set_role(:admin)
                one_job_for_every_state
                get state, format: :json
              end

              it 'succeeds' do
                assert_response :success
                json          = JSON.parse(response.body)
                expected_data = {
                  aborted:   {
                    "0"           => /#{RocketJob::Jobs::SimpleJob.name}/,
                    "1"           => '',
                    "2"           => /UTC/,
                    "3"           => /ms/,
                    "4"           => /\/jobs\/#{RocketJob::Jobs::SimpleJob.aborted.first.id}/,
                    "DT_RowClass" => "card callout callout-aborted"
                  },
                  failed:    {
                    "0"           => /#{RocketJob::Jobs::SimpleJob.name}/,
                    "1"           => '',
                    "2"           => /UTC/,
                    "3"           => /ms/,
                    "4"           => /\/jobs\/#{RocketJob::Jobs::SimpleJob.failed.first.id}/,
                    "DT_RowClass" => "card callout callout-failed"
                  },
                  paused:    {
                    "0"           => /#{RocketJob::Jobs::SimpleJob.name}/,
                    "1"           => '',
                    "2"           => /UTC/,
                    "3"           => /ms/,
                    "4"           => /\/jobs\/#{RocketJob::Jobs::SimpleJob.paused.first.id}/,
                    "DT_RowClass" => "card callout callout-paused"
                  },
                  completed: {
                    "0"           => /#{RocketJob::Jobs::SimpleJob.name}/,
                    "1"           => '',
                    "2"           => /UTC/,
                    "3"           => /ms/,
                    "4"           => /\/jobs\/#{RocketJob::Jobs::SimpleJob.completed.first.id}/,
                    "DT_RowClass" => "card callout callout-completed"
                  },
                  running:   {
                    "0"           => /#{RocketJob::Jobs::SimpleJob.name}/,
                    "1"           => '',
                    "2"           => /UTC/,
                    "3"           => /ms/,
                    "4"           => /\/jobs\/#{RocketJob::Jobs::SimpleJob.running.first.id}/,
                    "DT_RowClass" => "card callout callout-running"
                  },
                  queued:    {
                    "0"           => /#{RocketJob::Jobs::SimpleJob.name}/,
                    "1"           => '',
                    "2"           => /UTC/,
                    "3"           => /ms/,
                    "4"           => /\/jobs\/#{RocketJob::Jobs::SimpleJob.queued.first.id}/,
                    "DT_RowClass" => "card callout callout-queued"
                  },
                }

                if state == :index
                  assert_equal 0, json['draw']
                  assert_equal 6, json['recordsTotal']
                  assert_equal 6, json['recordsFiltered']
                  compare_array_of_hashes expected_data.values, json['data']
                else
                  assert_equal 0, json['draw']
                  assert_equal 1, json['recordsTotal']
                  assert_equal 1, json['recordsFiltered']
                  # Columns change by state
                  #compare_hash expected_data[state], json['data'].first
                end
              end
            end

          end

        end
      end

      describe 'role base authentication control' do
        %i[index aborted completed failed paused queued running scheduled].each do |method|
          it "#{method} has read access as default" do
            get method, format: :json
            assert_response :success
          end
        end

        %i[update abort retry pause resume run_now fail].each do |method|
          describe "#{method}" do
            before do
              case method
              when :pause, :fail, :abort
                pausable_job.start!
              when :resume
                pausable_job.pause!
              when :retry, :exception
                pausable_job.fail!
              end

              @params = {id: pausable_job.id, job: {id: pausable_job.id, priority: pausable_job.priority}}
              @params = {params: @params} if Rails.version.to_i >= 5
            end

            %i[admin editor operator manager].each do |role|
              it "redirects with #{method} method and role #{role}" do
                set_role(role)
                patch method, @params
                assert_response(:redirect)
              end
            end

            %i[dirmon user].each do |role|
              it "raises authentication error for #{role}" do
                set_role(role)
                assert_raises AccessGranted::AccessDenied do
                  patch method, @params
                end
              end
            end
          end
        end
      end
    end

    def set_role(r)
      Config.authorization_callback = -> do
        {roles: [r]}
      end
    end
  end
end
