require_relative "../../test_helper"
require_relative "../../compare_hashes"

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
        job = KaboomBatchJob.new
        job.input_category.slice_size = 1
        job.upload do |stream|
          stream << "first record"
          stream << "second record"
          stream << "third record"
        end
        job.save!

        # Run all 3 slices now to get exceptions for each.
        3.times do
          job.perform_now
        rescue ArgumentError, RuntimeError, EOFError
        end
        job
      end

      job_states = RocketJob::Job.aasm.states.collect(&:name)

      let :one_job_for_every_state do
        job_states.collect do |state|
          RocketJob::Jobs::SimpleJob.create!(state: state, worker_name: "worker", started_at: (Time.now - 0.5))
        end
      end

      %i[pause resume abort retry fail].each do |state|
        describe "PATCH ##{state}" do
          describe "with an invalid job id" do
            before do
              patch state, params: {id: 42, job: {id: 42, priority: 12}}
            end

            it "redirects" do
              assert_redirected_to jobs_path
            end

            it "adds a flash alert message" do
              assert_equal I18n.t("job.find.failure", id: 42), flash[:danger]
            end
          end

          describe "with a valid job id" do
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
              patch state, params: params
            end

            it "redirects to the job" do
              assert_redirected_to job_path(pausable_job.id)
            end

            it "transitions the job" do
              assert_not_equal state, pausable_job.state
            end
          end
        end
      end

      describe "PATCH #run_now" do
        let(:scheduled_job) { RocketJob::Jobs::SimpleJob.create!(run_at: 2.days.from_now) }

        before do
          patch :run_now, params: {id: scheduled_job.id}
        end

        it "redirects to the job path" do
          assert_redirected_to job_path(scheduled_job.id)
        end

        it "updates run_at" do
          assert_nil scheduled_job.reload.run_at
        end
      end

      describe "PATCH #update" do
        describe "with an invalid job id" do
          before do
            patch :update, params: {id: 42, job: {id: 42, priority: 12}}
          end

          it "redirects" do
            assert_redirected_to jobs_path
          end

          it "adds a flash alert message" do
            assert_equal I18n.t("job.find.failure", id: 42), flash[:danger]
          end
        end

        describe "with a valid job id" do
          before do
            params = {id: job.id, job: {id: job.id, priority: 12, blah: 23, description: "", log_level: "", state: "failed"}}
            patch :update, params: params
          end

          it "redirects to the job" do
            assert_redirected_to job_path(job.id)
          end

          it "updates the job correctly" do
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

      describe "GET #show" do
        describe "with an invalid job id" do
          before do
            get :show, params: {id: 42}
          end

          it "redirects" do
            assert_redirected_to jobs_path
          end

          it "adds a flash alert message" do
            assert_equal I18n.t("job.find.failure", id: 42), flash[:danger]
          end
        end

        describe "with a valid job id" do
          before do
            get :show, params: {id: job.id}
          end

          it "succeeds" do
            assert_response :success
          end

          it "assigns the job" do
            assert_equal job.id, assigns(:job).id
          end
        end
      end

      describe "GET #exception" do
        describe "with an invalid job id" do
          before do
            get :exception, params: {id: 42}
          end

          it "redirects" do
            assert_redirected_to jobs_path
          end

          it "adds a flash alert message" do
            assert_equal I18n.t("job.find.failure", id: 42), flash[:danger]
          end
        end

        describe "with a valid job id" do
          describe "without an exception" do
            before do
              get :exception, params: {id: failed_job.id, error_type: "Blah"}
            end

            it "redirects to job path" do
              assert_redirected_to job_path(failed_job.id)
            end

            it "notifies the user" do
              assert_equal I18n.t("job.failures.no_errors"), flash[:warning]
            end
          end

          describe "with exception" do
            # Derive the error type from a real failed slice so the test does not
            # depend on which error class KaboomBatchJob raised for each slice.
            let(:failed_slice) { failed_job.input.failed.order(_id: 1).first }
            let(:error_type)   { failed_slice.exception.class_name }

            before do
              get :exception, params: {id: failed_job.id, error_type: error_type}
            end

            it "succeeds" do
              assert_response :success
            end

            it "assigns the job" do
              assert_equal failed_job.id, assigns(:job).id
            end

            it "paginates" do
              expected_total = failed_job.input.failed.where("exception.class_name" => error_type).count - 1

              assert_equal 0,              assigns(:pagination)[:offset], assigns(:pagination)
              assert_equal expected_total, assigns(:pagination)[:total],  assigns(:pagination)
            end

            it "returns the first exception" do
              assert_equal error_type, assigns(:failure_exception).class_name
              assert_equal failed_slice.exception.message, assigns(:failure_exception).message
              assert_predicate assigns(:failure_exception).backtrace, :present?
            end
          end
        end
      end

      ([:index] + job_states).each do |state|
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
                one_job_for_every_state
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
                set_role(:admin)
                one_job_for_every_state
                get state, format: :json
              end

              it "succeeds" do
                assert_response :success
                json          = JSON.parse(response.body)
                expected_data = {
                  aborted:   {
                    "0"           => /#{RocketJob::Jobs::SimpleJob.name}/,
                    "1"           => "",
                    "2"           => /UTC/,
                    "3"           => /ms/,
                    "4"           => %r{/jobs/#{RocketJob::Jobs::SimpleJob.aborted.first.id}},
                    "DT_RowClass" => "rjmc-card callout callout-aborted"
                  },
                  failed:    {
                    "0"           => /#{RocketJob::Jobs::SimpleJob.name}/,
                    "1"           => "",
                    "2"           => /UTC/,
                    "3"           => /ms/,
                    "4"           => %r{/jobs/#{RocketJob::Jobs::SimpleJob.failed.first.id}},
                    "DT_RowClass" => "rjmc-card callout callout-failed"
                  },
                  paused:    {
                    "0"           => /#{RocketJob::Jobs::SimpleJob.name}/,
                    "1"           => "",
                    "2"           => /UTC/,
                    "3"           => /ms/,
                    "4"           => %r{/jobs/#{RocketJob::Jobs::SimpleJob.paused.first.id}},
                    "DT_RowClass" => "rjmc-card callout callout-paused"
                  },
                  completed: {
                    "0"           => /#{RocketJob::Jobs::SimpleJob.name}/,
                    "1"           => "",
                    "2"           => /UTC/,
                    "3"           => /ms/,
                    "4"           => %r{/jobs/#{RocketJob::Jobs::SimpleJob.completed.first.id}},
                    "DT_RowClass" => "rjmc-card callout callout-completed"
                  },
                  running:   {
                    "0"           => /#{RocketJob::Jobs::SimpleJob.name}/,
                    "1"           => "",
                    "2"           => /UTC/,
                    "3"           => /ms/,
                    "4"           => %r{/jobs/#{RocketJob::Jobs::SimpleJob.running.first.id}},
                    "DT_RowClass" => "rjmc-card callout callout-running"
                  },
                  queued:    {
                    "0"           => /#{RocketJob::Jobs::SimpleJob.name}/,
                    "1"           => "",
                    "2"           => /0/,
                    "3"           => /ms/,
                    "4"           => %r{/jobs/#{RocketJob::Jobs::SimpleJob.queued.first.id}},
                    "DT_RowClass" => "rjmc-card callout callout-queued"
                  }
                }

                assert_equal 0, json["draw"]
                if state == :index
                  assert_equal 6, json["recordsTotal"]
                  assert_equal 6, json["recordsFiltered"]
                  compare_array_of_hashes(expected_data.values, json["data"])
                else
                  assert_equal 1, json["recordsTotal"]
                  assert_equal 1, json["recordsFiltered"]
                  # Columns change by state
                  # compare_hash expected_data[state], json['data'].first
                end
              end
            end
          end
        end
      end

      describe "role base authentication control" do
        %i[index aborted completed failed paused queued running scheduled].each do |method|
          it "#{method} has read access as default" do
            get method, format: :json

            assert_response :success
          end
        end

        %i[update abort retry pause resume run_now fail].each do |method|
          describe method.to_s do
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
            end

            %i[admin editor operator manager].each do |role|
              it "redirects with #{method} method and role #{role}" do
                set_role(role)
                patch method, params: @params

                assert_response(:redirect)
              end
            end

            %i[dirmon user].each do |role|
              it "raises authentication error for #{role}" do
                set_role(role)
                assert_raises AccessGranted::AccessDenied do
                  patch method, params: @params
                end
              end
            end
          end
        end
      end

      # Derive the error type and slice from a real failed slice so the lookups
      # (which filter by error type) match the slice under test, regardless of
      # which error class KaboomBatchJob happened to raise for each slice.
      describe "#view_slice" do
        let(:failed_slice) { failed_job.input.failed.order(_id: 1).first }
        let(:error_type)   { failed_slice.exception.class_name }

        before do
          get :view_slice, params: {id: failed_job.id, error_type: error_type, offset: "0"}
        end

        it "succeeds" do
          assert_response :success
        end

        it "assigns the failed slice details" do
          assert_equal error_type,                          assigns(:failure_exception).class_name
          assert_equal failed_slice.current_record_number,  assigns(:failure_record_number)
          assert_equal failed_slice.first_record_number,    assigns(:first_record_number)
          assert_equal failed_slice.records,                assigns(:lines)
        end

        it "paginates from the requested offset" do
          assert_equal 0, assigns(:view_slice_pagination)[:offset]
          assert_equal failed_slice.processing_record_number, assigns(:view_slice_pagination)[:record_number]
        end

        it "renders the exception title and section" do
          assert_includes response.body, failed_job.class.name
          assert_includes response.body, "Exception"
          assert_includes response.body, error_type
          assert_includes response.body, failed_slice.exception.message
        end

        it "renders the records section with each record and its number" do
          assert_includes response.body, "Records"
          assert_includes response.body, "Content"
          failed_slice.records.each_with_index do |record, index|
            assert_includes response.body, record
            assert_includes response.body, (failed_slice.first_record_number + index).to_s
          end
        end

        it "highlights the failed record" do
          assert_includes response.body, "records-failed"
        end

        it "highlights unprintable bytes in a record" do
          failed_slice.records = ["null\x00byte"]
          failed_slice.save!
          get :view_slice, params: {id: failed_job.id, error_type: error_type, offset: "0"}

          assert_includes response.body, "record-escape"
          assert_includes response.body, "\\x00"
        end
      end

      describe "#edit_slice" do
        let(:failed_slice) { failed_job.input.failed.order(_id: 1).first }
        let(:error_type)   { failed_slice.exception.class_name }

        before do
          get :edit_slice, params: {id: failed_job.id, error_type: error_type, offset: "0", line_index: "0"}
        end

        it "succeeds" do
          assert_response :success
        end

        it "assigns the slice details" do
          assert_equal error_type,                       assigns(:failure_exception).class_name
          assert_equal failed_slice.first_record_number, assigns(:first_record_number)
          assert_equal failed_slice.records,             assigns(:lines)
          assert_equal 0,                                assigns(:line_index)
        end

        it "renders the edit slice title and record header" do
          assert_includes response.body, "Edit Slice"
          assert_includes response.body, "Edit Record: #{failed_slice.first_record_number}"
        end

        it "renders an editable text area for the record" do
          assert_match(/<textarea[^>]*input_slices/, response.body)
        end

        it "shows unprintable bytes as escapes in the text area" do
          failed_slice.records = ["null\x00byte"]
          failed_slice.save!
          get :edit_slice, params: {id: failed_job.id, error_type: error_type, offset: "0", line_index: "0"}

          assert_includes response.body, "null\\x00byte"
        end

        it "confirms deletion with the record number" do
          assert_includes response.body, "Record #{failed_slice.first_record_number} will be deleted from the slice."
        end
      end

      describe "#update slice" do
        # Derive the error type from an actual failed slice so the lookup (which
        # filters by error type) matches the slice that was edited.
        let(:error_type) { failed_job.input.failed.order(_id: 1).first.exception.class_name }

        before do
          params = {"job" => {"records" => %w[1 2 3]}, "error_type" => error_type, "offset" => "0", "id" => failed_job.id.to_s}
          post :update_slice, params: params
        end

        it "redirects back to the same slice" do
          assert_redirected_to view_slice_job_path(failed_job, error_type: error_type, offset: 0)
        end

        it "adds a flash success message" do
          assert_equal "slice updated", flash[:success]
        end

        it "unescapes submitted records back to their original bytes" do
          slice = failed_job.input.failed.order(_id: 1).first
          post :update_slice, params: {
            "job"        => {"records" => ["null\\x00byte"]},
            "error_type" => slice.exception.class_name,
            "offset"     => "0",
            "id"         => failed_job.id.to_s
          }
          slice.reload

          assert_equal "null\x00byte", slice.records.first
        end

        it "reports an error instead of raising when a record cannot be stored" do
          slice = failed_job.input.failed.order(_id: 1).first
          # \xA3 unescapes to an invalid UTF-8 byte, which Mongo cannot store.
          post :update_slice, params: {
            "job"        => {"records" => ["bad\\xA3byte"]},
            "error_type" => slice.exception.class_name,
            "offset"     => "0",
            "id"         => failed_job.id.to_s
          }

          assert_response :redirect
          assert_predicate flash[:danger], :present?
        end
      end

      describe "GET #edit" do
        describe "with a valid job id" do
          before do
            get :edit, params: {id: job.id}
          end

          it "succeeds" do
            assert_response :success
          end

          it "assigns the job" do
            assert_equal job.id, assigns(:job).id
          end
        end

        describe "with an invalid job id" do
          before do
            get :edit, params: {id: 42}
          end

          it "redirects" do
            assert_redirected_to jobs_path
          end
        end
      end

      describe "DELETE #destroy" do
        describe "with a valid job id" do
          before do
            job
            delete :destroy, params: {id: job.id}
          end

          it "redirects to the jobs list" do
            assert_redirected_to jobs_path
          end

          it "removes the job" do
            assert_nil RocketJob::Job.where(id: job.id).first
          end
        end

        describe "with an invalid job id" do
          before do
            delete :destroy, params: {id: 42}
          end

          it "redirects" do
            assert_redirected_to jobs_path
          end
        end
      end

      describe "PATCH #update with an invalid value" do
        before do
          # priority must be within 1..100, so this fails validation and the
          # controller re-renders the edit form instead of redirecting.
          patch :update, params: {id: job.id, job: {id: job.id, priority: 500}}
        end

        it "re-renders the edit form" do
          assert_response :success
          assert_template :edit
        end

        it "does not persist the invalid value" do
          assert_equal 50, job.reload.priority
        end
      end

      describe "PATCH #delete_line" do
        let(:error_type) { failed_job.input.failed.order(_id: 1).first.exception.class_name }

        before do
          patch :delete_line, params: {id: failed_job.id, error_type: error_type, offset: "0", line_index: "0"}
        end

        it "redirects to the slice view" do
          assert_redirected_to view_slice_job_path(failed_job, error_type: error_type, offset: 0)
        end

        it "adds a flash success message" do
          assert_match(/removed from the slice/, flash[:success])
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
