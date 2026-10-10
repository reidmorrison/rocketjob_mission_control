require_relative "../../test_helper"

module RocketJobMissionControl
  class ApplicationHelperTest < ActionView::TestCase
    describe ApplicationHelper do
      describe "#state_icon" do
        RocketJobMissionControl::ApplicationHelper::STATE_ICON_MAP.each do |state, expected_class|
          describe "when the job state is #{state}" do
            it "returns the correct class" do
              assert_equal "#{expected_class} #{state}", state_icon(state)
            end
          end
        end
      end

      describe "#pretty_print_array_or_hash" do
        let(:arguments) { [42, "muad'dib"] }
        let(:helper_output) { pretty_print_array_or_hash(arguments) }

        describe "when arguments is a simple array" do
          it "returns a string with spacing and line breaks" do
            assert_equal "[<br />  42,<br />  \"muad'dib\"<br />]", helper_output
          end
        end

        describe "when arguments is an array with complex data" do
          let(:arguments) do
            [
              42,
              {
                crew:       %w[leela fry bender],
                created_at: "1999-03-28"
              }
            ]
          end

          it "returns a string with spacing and line breaks" do
            expected_output = "[<br />  42,<br />  {<br />    \"crew\": [<br />      \"leela\",<br />      \"fry\",<br />      \"bender\"<br />    ],<br />    \"created_at\": \"1999-03-28\"<br />  }<br />]"

            assert_equal expected_output, helper_output
          end
        end

        describe "when arguments isn't an array or hash" do
          let(:arguments) { 42 }

          it "returns the arguments" do
            assert_equal arguments, helper_output
          end
        end
      end

      describe "#state?" do
        it "is true for a known state" do
          assert state?("completed")
        end

        it "is case insensitive" do
          assert state?("Running")
        end

        it "is false for an unknown state" do
          assert_not state?("bogus")
        end
      end

      describe "#render_json_tree" do
        it "wraps the value in a json-tree container" do
          html = render_json_tree({"a" => 1})

          assert_match(/class="json-tree"/, html)
          assert_match(%r{<script type="application/json">}, html)
        end

        it "renders a noscript plain-text fallback" do
          html = render_json_tree([1, 2, 3])

          assert_match(/<noscript>/, html)
          assert_match(/<pre>/, html)
        end

        it "does not collapse small collections" do
          html = render_json_tree((1..5).to_a)

          assert_match(/data-collapsed="false"/, html)
        end

        it "collapses collections past the threshold" do
          html = render_json_tree((1..20).to_a)

          assert_match(/data-collapsed="true"/, html)
        end
      end

      describe "#extract_inclusion_values" do
        it "returns the inclusion list for a validated attribute" do
          klass = Class.new do
            include ActiveModel::Validations

            attr_accessor :color

            validates :color, inclusion: {in: %w[red green blue]}
          end

          assert_equal %w[red green blue], extract_inclusion_values(klass, :color)
        end

        it "returns nil when the attribute has no inclusion validator" do
          klass = Class.new do
            include ActiveModel::Validations

            attr_accessor :name

            validates :name, presence: true
          end

          assert_nil extract_inclusion_values(klass, :name)
        end
      end

      describe "#encoding_field?" do
        it "is true for an attribute that is validated as an encoding" do
          assert encoding_field?(RocketJob::Category::Input, :encoding)
          assert encoding_field?(RocketJob::Jobs::CopyFileJob, :target_encoding)
        end

        it "is false for any other attribute" do
          assert_not encoding_field?(RocketJob::Category::Input, :format)
          assert_not encoding_field?(RocketJob::Jobs::CopyFileJob, :source_url)
        end
      end

      describe "#encoding_select" do
        let :category do
          RocketJob::Category::Input.new
        end

        def render_select(value)
          category.encoding = value
          fields_for(:category, category) { |f| encoding_select(f, :encoding, value) }
        end

        it "suggests the common encodings, with a blank for UTF-8" do
          html = render_select(nil)

          assert_includes html, 'class="tom-select form-select"'
          assert_includes html, '<option value="" label=" "></option>'
          ApplicationHelper::SUGGESTED_ENCODINGS.each { |name| assert_includes html, ">#{name}</option>" }
        end

        it "selects a suggested encoding" do
          assert_includes render_select("Windows-1252"), '<option selected="selected" value="Windows-1252">'
        end

        it "selects an encoding that is not suggested, such as one that was typed in" do
          html = render_select("EUC-JP")

          assert_includes html, '<option selected="selected" value="EUC-JP">'
          assert_operator html.index("EUC-JP"), :<, html.index("UTF-8")
        end

        it "escapes the encoding, since it is typed in" do
          assert_includes render_select("<b>"), "&lt;b&gt;"
          assert_not_includes render_select("<b>"), "<b>"
        end
      end

      describe "#editable_field_html" do
        it "selects the encoding of a field that is validated as one" do
          job  = RocketJob::Jobs::CopyFileJob.new(target_encoding: "ISO-8859-1")
          html = fields_for(:job, job) { |f| editable_field_html(job.class, :target_encoding, job.target_encoding, f) }

          assert_includes html, 'name="job[target_encoding]"'
          assert_includes html, '<option selected="selected" value="ISO-8859-1">'
        end
      end
    end
  end
end
