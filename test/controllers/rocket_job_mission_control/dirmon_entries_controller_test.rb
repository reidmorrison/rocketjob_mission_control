require_relative "../../test_helper"
require_relative "../../compare_hashes"

module RocketJobMissionControl
  class DirmonEntriesControllerTest < ActionController::TestCase
    # A job that a Dirmon entry can start, since it receives the file in `full_file_name`, with a path in its
    # properties, which can include credentials.
    class CopyToJob < RocketJob::Job
      field :full_file_name, type: String
      field :target_url, type: String, user_editable: true, path: true

      def perform
      end
    end

    describe DirmonEntriesController do
      before do
        set_role(:admin)
        RocketJob::DirmonEntry.delete_all
      end

      # A Dirmon entry's job class must be able to receive a file, see RocketJob::DirmonEntry.
      let :job_class_name do
        "DataImportJob"
      end

      let :existing_dirmon_entry do
        RocketJob::DirmonEntry.create!(
          name:           "Existing path test",
          job_class_name: job_class_name,
          pattern:        "existing_path"
        )
      end

      let :sftp_dirmon_entry do
        RocketJob::DirmonEntry.create!(
          name:              "SFTP path test",
          job_class_name:    job_class_name,
          pattern:           "sftp://user:secret@sftp.example.org/in/*.csv",
          archive_directory: "sftp://user:secret@sftp.example.org/archive"
        )
      end

      dirmon_entry_states = RocketJob::DirmonEntry.aasm.states.collect(&:name)

      let :one_dirmon_entry_for_every_state do
        dirmon_entry_states.collect do |state|
          RocketJob::DirmonEntry.create!(
            name:           "Test_for_state_#{state}",
            job_class_name: job_class_name,
            pattern:        "path_for_state_#{state}",
            state:          state
          )
        end
      end

      describe "PATCH #enable" do
        describe "when transition is allowed" do
          before do
            patch :enable, params: {id: existing_dirmon_entry.id}
          end

          it do
            assert_redirected_to dirmon_entry_path(existing_dirmon_entry)
          end

          it "changes the state to enabled" do
            assert_predicate existing_dirmon_entry.reload, :enabled?
          end
        end

        describe "when transition is not allowed" do
          before do
            existing_dirmon_entry.enable!
            patch :enable, params: {id: existing_dirmon_entry.id}
          end

          it "succeeds" do
            assert_response :success
          end

          it "alerts the user" do
            assert_equal I18n.t("dirmon_entry.enable.failure"), flash[:danger]
          end
        end
      end

      describe "PATCH #disable" do
        describe "when transition is allowed" do
          before do
            existing_dirmon_entry.enable!
            patch :disable, params: {id: existing_dirmon_entry.id}
          end

          it do
            assert_redirected_to dirmon_entry_path(existing_dirmon_entry)
          end

          it "changes the state to disabled" do
            assert_predicate existing_dirmon_entry.reload, :disabled?
          end
        end

        describe "when transition is not allowed" do
          before do
            patch :disable, params: {id: existing_dirmon_entry.id}
          end

          it "succeeds" do
            assert_response :success
          end

          it "alerts the user" do
            assert_equal I18n.t("dirmon_entry.disable.failure"), flash[:danger]
          end
        end
      end

      describe "GET #new" do
        let(:entry_params) { {} }

        before do
          get :new, params: entry_params
        end

        it "succeeds" do
          assert_response :success
        end

        it "assigns a new entry" do
          assert_predicate assigns(:dirmon_entry), :present?
          assert_not assigns(:dirmon_entry).persisted?
        end

        describe "with form params" do
          let(:entry_params) { {rocket_job_dirmon_entry: {name: "new entry"}} }

          it "succeeds" do
            assert_response :success
          end

          it "assigns the params to new entry" do
            assert_equal "new entry", assigns(:dirmon_entry).name
          end

          describe "with a valid job_class_name" do
            let(:entry_params) { {rocket_job_dirmon_entry: {job_class_name: "NoParamsJob"}} }

            it "succeeds" do
              assert_response :success
            end

            it "assigns the job class" do
              assert_equal "NoParamsJob", assigns(:dirmon_entry).job_class_name
            end
          end

          describe "with an invalid job_class_name" do
            let(:entry_params) { {rocket_job_dirmon_entry: {job_class_name: "BadJob"}} }

            it "succeeds" do
              assert_response :success
            end

            it "adds an error" do
              assert_predicate assigns(:dirmon_entry).errors[:job_class_name], :present?
            end
          end

          describe "with a batch job_class_name" do
            let(:entry_params) { {rocket_job_dirmon_entry: {job_class_name: "DataImportJob"}} }

            it "shows the schema of each category" do
              assert_match(/<textarea[^>]*input_categories_attributes\]\[[^\]]*\]\[schema\]/, response.body)
              assert_match(/<textarea[^>]*output_categories_attributes\]\[[^\]]*\]\[schema\]/, response.body)
            end

            it "shows validate_rows of each input category, rather than mode" do
              assert_match(/<select[^>]*input_categories_attributes\]\[[^\]]*\]\[validate_rows\]/, response.body)
              assert_no_match(/input_categories_attributes\]\[[^\]]*\]\[mode\]/, response.body)
            end
          end
        end
      end

      describe "PATCH #update" do
        describe "with valid parameters" do
          before do
            params = {id: existing_dirmon_entry.id, rocket_job_dirmon_entry: {pattern: "the_path2", job_class_name: job_class_name}}
            patch :update, params: params
          end

          it "redirects to the updated entry" do
            assert_redirected_to dirmon_entry_path(existing_dirmon_entry)
          end

          it "updates the entry" do
            assert_equal "the_path2", existing_dirmon_entry.reload.pattern
          end
        end

        describe "with invalid parameters" do
          before do
            params = {id: existing_dirmon_entry.id, rocket_job_dirmon_entry: {job_class_name: "FakeAndBadJob"}}
            patch :update, params: params
          end

          it "renders the edit template" do
            assert_response :unprocessable_content
          end

          it "alerts the user" do
            if RocketJob::VERSION.to_f >= 3.5
              assert_select "div.message", "job_class_name: [\"Job FakeAndBadJob must be defined and inherit from RocketJob::Job\"]"
            else
              assert_select "div.message", "job_class_name: [\"job_class_name must be defined and must be derived from RocketJob::Job\"]"
            end
          end
        end

        describe "for a batch job" do
          let :saved_properties do
            {
              "region"            => "eu-west",
              "input_categories"  => [
                {
                  "name"            => "main",
                  "format"          => "psv",
                  "columns"         => %w[name age],
                  "skip_unknown"    => true,
                  "allowed_columns" => %w[name age],
                  "header_cleanser" => "none",
                  "file_name"       => "sftp://user:secret@example.com/in.csv",
                  "slice_size"      => 10
                }
              ],
              "output_categories" => [{"name" => "main", "format" => "json", "nils" => true}]
            }
          end

          let :entry do
            RocketJob::DirmonEntry.create!(
              name:           "Batch",
              job_class_name: job_class_name,
              pattern:        "batch/*.csv",
              properties:     saved_properties
            )
          end

          # The properties that the edit form posts for the entry, unchanged, see dirmon_entries/_form.html.erb.
          let :form_properties do
            {
              description:                  "",
              log_level:                    "",
              priority:                     "50",
              region:                       "eu-west",
              throttle_group:               "",
              throttle_running_workers:     "",
              input_categories_attributes:  {
                "0" => {name: "main", columns: ["", "name", "age"], format: "psv", schema: "", format_options: "",
                        mode: "line", skip_unknown: "true", slice_size: "10"}
              },
              output_categories_attributes: {
                "1" => {name: "main", columns: [""], format: "json", schema: "", format_options: ""}
              }
            }
          end

          def update_properties(properties)
            patch :update, params: {id: entry.id, rocket_job_dirmon_entry: {name: "Renamed", properties: properties}}

            assert_redirected_to dirmon_entry_path(entry)
            entry.reload.properties
          end

          it "keeps the properties that its form does not show" do
            properties = update_properties(form_properties)
            input      = properties["input_categories"].first

            assert_equal %w[name age], input["allowed_columns"]
            assert_equal "none", input["header_cleanser"]
            assert_equal "sftp://user:secret@example.com/in.csv", input["file_name"]
            assert properties["output_categories"].first["nils"]
          end

          it "keeps the properties that its form shows" do
            properties = update_properties(form_properties)
            input      = properties["input_categories"].first

            assert_equal "eu-west", properties["region"]
            assert_equal "psv", input["format"]
            assert_equal %w[name age], input["columns"]
            assert_equal "json", properties["output_categories"].first["format"]
          end

          it "saves each category value with the type of its field" do
            input = update_properties(form_properties)["input_categories"].first

            assert_equal [true, 10], input.values_at("skip_unknown", "slice_size")
          end

          it "removes a property that its form clears" do
            form_properties[:region] = ""
            form_properties[:input_categories_attributes]["0"][:columns] = [""]
            properties = update_properties(form_properties)
            input      = properties["input_categories"].first

            assert_not properties.key?("region")
            assert_not input.key?("columns")
            assert_equal %w[name age], input["allowed_columns"]
          end

          it "removes a property that its form sets to the job class's default" do
            form_properties[:input_categories_attributes]["0"][:format]  = "csv"
            form_properties[:output_categories_attributes]["1"][:format] = "csv"
            properties = update_properties(form_properties)

            assert_not properties["input_categories"].first.key?("format")
            assert_equal({"name" => "main", "nils" => true}, properties["output_categories"].first)
          end

          it "removes the options that a schema replaces when its form gives a category a schema" do
            form_properties[:input_categories_attributes]["0"][:schema]       = %({"fields": [{"name": "name"}]})
            form_properties[:input_categories_attributes]["0"][:skip_unknown] = "false"
            properties = update_properties(form_properties)
            input      = properties["input_categories"].first

            assert_equal({"fields" => [{"name" => "name"}]}, input["schema"])
            assert_not input.key?("allowed_columns")
            assert_not input.key?("header_cleanser")
            assert_equal "sftp://user:secret@example.com/in.csv", input["file_name"]
            assert_predicate DataImportJob.from_properties(properties).input_category, :valid?
          end

          it "keeps every property when its form posts none" do
            patch :update, params: {id: entry.id, rocket_job_dirmon_entry: {name: "Renamed"}}

            assert_equal "Renamed", entry.reload.name
            assert_equal saved_properties, entry.properties
          end
        end
      end

      describe "POST #create" do
        describe "with valid parameters" do
          let(:dirmon_params) do
            {
              name:           "Test",
              pattern:        "/files/*",
              job_class_name: job_class_name,
              properties:     {description: "", priority: "42"}
            }
          end

          before do
            post :create, params: {rocket_job_dirmon_entry: dirmon_params}
          end

          it "creates the entry" do
            assert_predicate assigns(:dirmon_entry), :persisted?
          end

          it "has no errors" do
            assert_empty assigns(:dirmon_entry).errors.messages
          end

          it "redirects to created entry" do
            assert_redirected_to dirmon_entry_path(assigns(:dirmon_entry))
          end

          it "does not save blank properties" do
            assert_nil assigns(:dirmon_entry).properties[:description]
          end

          it "saves properties" do
            assert_equal "42", assigns(:dirmon_entry).properties[:priority]
          end

          describe "for a batch job with a schema" do
            let(:dirmon_params) do
              {
                name:           "Test",
                pattern:        "/files/*",
                job_class_name: "DataImportJob",
                properties:     {input_categories_attributes: {"0" => {name: "main", schema: %({"fields": [{"name": "name"}]})}}}
              }
            end

            it "saves the schema of the files" do
              assert_predicate assigns(:dirmon_entry), :persisted?
              category = assigns(:dirmon_entry).properties[:input_categories].first

              assert_equal({"fields" => [{"name" => "name"}]}, category[:schema])
            end
          end

          describe "for a batch job that validates the rows of its files" do
            let(:dirmon_params) do
              {
                name:           "Test",
                pattern:        "/files/*",
                job_class_name: "DataImportJob",
                properties:     {input_categories_attributes: {"0" => {name: "main", validate_rows: "true"}}}
              }
            end

            it "saves validate_rows" do
              assert_predicate assigns(:dirmon_entry), :persisted?
              category = assigns(:dirmon_entry).properties[:input_categories].first

              # The Boolean, rather than the "true" of the form.
              assert_same true, category[:validate_rows]
            end
          end

          %i[name pattern job_class_name].each do |attribute|
            it "assigns the correct value for #{attribute}" do
              assert_equal dirmon_params[attribute], assigns(:dirmon_entry)[attribute]
            end
          end
        end

        describe "with invalid parameters" do
          let(:dirmon_params) do
            {
              name:           "Test",
              job_class_name: "FakeAndBadJob"
            }
          end

          before do
            post :create, params: {rocket_job_dirmon_entry: dirmon_params}
          end

          describe "on model attributes" do
            it "renders the new template" do
              assert_response :unprocessable_content
              assert_template :new
            end

            it "has errors on the entry" do
              assert_not assigns(:dirmon_entry).valid?
            end
          end
        end
      end

      describe "GET #edit" do
        before do
          get :edit, params: {id: existing_dirmon_entry.id}
        end

        it "succeeds" do
          assert_response :success
        end

        it "assigns the entry" do
          assert_equal existing_dirmon_entry, assigns(:dirmon_entry)
        end
      end

      describe "an input category that validates its lines without validate_rows" do
        # Rocket Job reports the deprecated :hash mode of each job built from these properties while Ruby's deprecation
        # warnings are on, as they are in tests.
        before do
          @deprecated          = Warning[:deprecated]
          Warning[:deprecated] = false
        end

        after do
          Warning[:deprecated] = @deprecated
        end

        let :schema do
          {"fields" => [{"name" => "name"}]}
        end

        # The deprecated :hash mode with a schema validates the lines, and Rocket Job 8 reads it as validate_rows: true.
        let :hash_mode_entry do
          RocketJob::DirmonEntry.create!(
            name:           "Hash mode",
            job_class_name: job_class_name,
            pattern:        "hash_mode/*.csv",
            properties:     {"input_categories" => [{"name" => "main", "mode" => "hash", "schema" => schema}]}
          )
        end

        def update_validate_rows(value)
          patch :update, params: {
            id:                      hash_mode_entry.id,
            rocket_job_dirmon_entry: {
              properties: {
                input_categories_attributes: {"0" => {name: "main", schema: schema.to_json, validate_rows: value}}
              }
            }
          }
          hash_mode_entry.reload
        end

        def validates_rows?(entry)
          entry.job_class.from_properties(entry.properties).input_category.upload_validates_rows?
        end

        it "shows validate_rows as true" do
          get :edit, params: {id: hash_mode_entry.id}

          assert_select "select[name$='[validate_rows]'] option[selected][value='true']"
        end

        it "saves validate_rows as the form shows it" do
          entry = update_validate_rows("true")

          assert_same true, entry.properties["input_categories"].first["validate_rows"]
          assert validates_rows?(entry)
        end

        it "still validates them when validate_rows is left blank" do
          assert validates_rows?(update_validate_rows(""))
        end
      end

      describe "GET #show" do
        describe "with an invalid id" do
          before do
            get :show, params: {id: 42}
          end

          it "redirects" do
            assert_redirected_to dirmon_entries_path
          end

          it "adds a flash alert message" do
            assert_equal I18n.t("dirmon_entry.find.failure", id: 42), flash[:danger]
          end
        end

        describe "with a valid id" do
          before do
            get :show, params: {id: existing_dirmon_entry.id}
          end

          it "succeeds" do
            assert_response :success
          end

          it "assigns the entry" do
            assert_predicate assigns(:dirmon_entry), :present?
          end
        end

        describe "with credentials in its pattern and archive directory" do
          before do
            get :show, params: {id: sftp_dirmon_entry.id}
          end

          it "shows them without the credentials" do
            assert_includes response.body, "sftp://sftp.example.org/in/*.csv"
            assert_includes response.body, "sftp://sftp.example.org/archive"
            assert_not_includes response.body, "secret"
          end
        end

        describe "with credentials in a path of its properties" do
          before do
            entry = RocketJob::DirmonEntry.create!(
              name:           "Copy test",
              job_class_name: CopyToJob.name,
              pattern:        "copy_path",
              properties:     {"target_url" => "sftp://user:secret@sftp.example.org/out/data.csv"}
            )
            get :show, params: {id: entry.id}
          end

          it "shows the path without the credentials" do
            assert_includes response.body, "sftp://sftp.example.org/out/data.csv"
            assert_not_includes response.body, "secret"
          end
        end
      end

      describe "GET #index json with credentials in a pattern" do
        before do
          sftp_dirmon_entry
          get :index, format: :json
        end

        it "shows the pattern without the credentials" do
          row = JSON.parse(response.body)["data"].first

          assert_equal "sftp://sftp.example.org/in/*.csv", row["2"]
          assert_not_includes response.body, "secret"
        end
      end

      describe "GET #index json searching a pattern with credentials" do
        def records_found(role, term)
          set_role(role)
          get :index, format: :json, params: {search: {value: term}}
          JSON.parse(response.body)["recordsFiltered"]
        end

        before do
          sftp_dirmon_entry
        end

        it "searches the pattern for a role that can edit an entry" do
          assert_equal 1, records_found(:dirmon, "user:secret")
        end

        it "does not search the pattern for a role that cannot see it as stored" do
          assert_equal 0, records_found(:view, "user:s")
          assert_equal 1, records_found(:view, "SFTP path")
        end
      end

      describe "DELETE #destroy" do
        describe "with a valid id" do
          before do
            delete :destroy, params: {id: existing_dirmon_entry.id}
          end

          it "redirects to index" do
            assert_redirected_to dirmon_entries_path
          end

          it "deletes the entry" do
            assert_not RocketJob::DirmonEntry.where(id: existing_dirmon_entry.id).exists?
          end
        end
      end

      describe "GET #copy" do
        before do
          get :copy, params: {id: existing_dirmon_entry.id}
        end

        it "succeeds" do
          assert_response :success
        end

        it "assigns the entry" do
          assert_equal existing_dirmon_entry, assigns(:dirmon_entry)
        end
      end

      describe "PATCH #replicate" do
        describe "with valid parameters" do
          before do
            patch :replicate, params: {
              id:                      existing_dirmon_entry.id,
              rocket_job_dirmon_entry: {
                name:           "Replicated entry",
                pattern:        "replicated_path",
                job_class_name: job_class_name,
                properties:     {}
              }
            }
          end

          it "redirects to the new entry" do
            new_entry = RocketJob::DirmonEntry.where(name: "Replicated entry").first

            assert_redirected_to dirmon_entry_path(new_entry)
          end

          it "creates a copy without destroying the original" do
            assert_predicate RocketJob::DirmonEntry.where(name: "Replicated entry"), :exists?
            assert_predicate RocketJob::DirmonEntry.where(id: existing_dirmon_entry.id), :exists?
          end
        end

        describe "for a batch job" do
          let :batch_entry do
            RocketJob::DirmonEntry.create!(
              name:           "Batch",
              job_class_name: job_class_name,
              pattern:        "batch/*.csv",
              properties:     {
                "region"           => "eu-west",
                "input_categories" => [{"name" => "main", "format" => "psv", "allowed_columns" => %w[name age]}]
              }
            )
          end

          it "keeps the properties that its form does not show, with those that it changes" do
            patch :replicate, params: {
              id:                      batch_entry.id,
              rocket_job_dirmon_entry: {
                name:       "Copied",
                pattern:    "copied/*.csv",
                properties: {region: "us-west", input_categories_attributes: {"0" => {name: "main", format: "psv"}}}
              }
            }
            copy = RocketJob::DirmonEntry.where(name: "Copied").first

            assert_equal(
              {
                "region"           => "us-west",
                "input_categories" => [{"name" => "main", "format" => "psv", "allowed_columns" => %w[name age]}]
              },
              copy.properties
            )
          end
        end

        describe "of an enabled entry" do
          before do
            existing_dirmon_entry.enable!
            patch :replicate, params: {
              id:                      existing_dirmon_entry.id,
              rocket_job_dirmon_entry: {name: "Replicated entry", pattern: "replicated_path", properties: {}}
            }
          end

          it "creates a pending copy" do
            new_entry = RocketJob::DirmonEntry.where(name: "Replicated entry").first

            assert_predicate new_entry, :pending?
            assert_equal job_class_name, new_entry.job_class_name
          end
        end

        describe "with invalid parameters" do
          before do
            patch :replicate, params: {
              id:                      existing_dirmon_entry.id,
              rocket_job_dirmon_entry: {name: "Broken", job_class_name: "FakeAndBadJob"}
            }
          end

          it "re-renders the copy form" do
            assert_response :unprocessable_content
            assert_template :copy
          end

          it "carries the validation errors on the entry" do
            assert_predicate assigns(:dirmon_entry).errors, :present?
          end
        end
      end

      ([:index] + dirmon_entry_states).each do |state|
        describe "GET ##{state}" do
          describe "html" do
            describe "with no #{state} entries" do
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

            describe "with #{state} entries" do
              before do
                one_dirmon_entry_for_every_state
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
            describe "with #{state} entries" do
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

            describe "with #{state} entries" do
              before do
                one_dirmon_entry_for_every_state
                get state, format: :json
              end

              it "succeeds" do
                assert_response :success
                json          = JSON.parse(response.body)
                expected_data = {
                  pending:  {
                    "0"           => "        <a href=\"/dirmon_entries/#{RocketJob::DirmonEntry.pending.first.id}\">\n          <i class=\"fa-solid fa-cogs pending\" style=\"font-size: 75%\" title=\"pending\"></i>\n          Test_for_state_pending\n        </a>\n",
                    "1"           => job_class_name,
                    "2"           => "path_for_state_pending",
                    "DT_RowClass" => "rjmc-card callout callout-pending"
                  },
                  enabled:  {
                    "0"           => "        <a href=\"/dirmon_entries/#{RocketJob::DirmonEntry.enabled.first.id}\">\n          <i class=\"fa-solid fa-circle-check enabled\" style=\"font-size: 75%\" title=\"enabled\"></i>\n          Test_for_state_enabled\n        </a>\n",
                    "1"           => job_class_name,
                    "2"           => "path_for_state_enabled",
                    "DT_RowClass" => "rjmc-card callout callout-enabled"
                  },
                  failed:   {
                    "0"           => "        <a href=\"/dirmon_entries/#{RocketJob::DirmonEntry.failed.first.id}\">\n          <i class=\"fa-solid fa-triangle-exclamation failed\" style=\"font-size: 75%\" title=\"failed\"></i>\n          Test_for_state_failed\n        </a>\n",
                    "1"           => job_class_name,
                    "2"           => "path_for_state_failed",
                    "DT_RowClass" => "rjmc-card callout callout-failed"
                  },
                  disabled: {
                    "0"           => "        <a href=\"/dirmon_entries/#{RocketJob::DirmonEntry.disabled.first.id}\">\n          <i class=\"fa-solid fa-ban disabled\" style=\"font-size: 75%\" title=\"disabled\"></i>\n          Test_for_state_disabled\n        </a>\n",
                    "1"           => job_class_name,
                    "2"           => "path_for_state_disabled",
                    "DT_RowClass" => "rjmc-card callout callout-disabled"
                  }
                }

                assert_equal 0, json["draw"]
                if state == :index
                  assert_equal 4, json["recordsTotal"]
                  assert_equal 4, json["recordsFiltered"]
                  assert_equal [expected_data[:disabled], expected_data[:enabled], expected_data[:failed], expected_data[:pending]], json["data"]
                else
                  assert_equal 1, json["recordsTotal"]
                  assert_equal 1, json["recordsFiltered"]
                  assert_equal [expected_data[state]], json["data"]
                end
              end
            end
          end
        end
      end

      describe "role base authentication control" do
        let(:dirmon_params) do
          {
            name:           "Test",
            pattern:        "/files/*",
            job_class_name: job_class_name,
            properties:     {description: "", priority: "42"}
          }
        end

        %i[index disabled enabled failed pending].each do |method|
          it "#{method} has read only default access" do
            get method, format: :json

            assert_response :success
          end
        end

        # PATCH
        %i[enable disable update].each do |method|
          describe method.to_s do
            %i[admin editor operator manager dirmon].each do |role|
              it "allows role #{role} to access #{method}" do
                set_role(role)
                patch :enable, params: {id: existing_dirmon_entry.id}

                assert_response(:redirect)
              end
            end
          end
        end

        # POST
        %i[admin editor operator manager dirmon].each do |role|
          it "creates dirmon entry" do
            set_role(role)
            post :create, params: {rocket_job_dirmon_entry: dirmon_params}

            assert_response(:redirect)
          end
        end

        it "deletes dirmon entry" do
          set_role(:admin)
          delete :destroy, params: {id: existing_dirmon_entry.id}

          assert_response(:redirect)
        end

        %i[editor operator manager dirmon].each do |role|
          it "raises authentication error for #{role}" do
            set_role(role)
            assert_raises AccessGranted::AccessDenied do
              delete :destroy, params: {id: existing_dirmon_entry.id}
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
