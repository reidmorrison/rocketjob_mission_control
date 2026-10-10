require_relative "../../test_helper"

class RecordEditorTest < Minitest::Test
  describe RocketJobMissionControl::RecordEditor do
    let(:editor) { RocketJobMissionControl::RecordEditor }

    describe "a String record" do
      it "is edited as its text, with each unprintable byte escaped" do
        assert_equal "null\\x00byte", editor.to_text("null\x00byte")
      end

      it "is converted back into the same bytes" do
        assert_equal "null\x00byte", editor.from_text("null\\x00byte", "any text")
      end

      it "is viewed as it is" do
        assert_equal "José", editor.to_display_text("José")
      end
    end

    describe "a record that is not a String" do
      [
        {"name" => "José", "count" => 1, "price" => 1.5, "tags" => %w[a b], "none" => nil},
        ["Jack", 2],
        [200, 299],
        42,
        nil,
        true
      ].each do |record|
        it "is converted back into the same #{record.class.name}" do
          assert_equal record, editor.from_text(editor.to_text(record), record)
        end
      end

      it "keeps the types of values that JSON does not have, such as a time or an object id" do
        record = {"at" => Time.at(1_760_000_000, 123, :millisecond).utc, "id" => BSON::ObjectId.new}

        assert_equal record, editor.from_text(editor.to_text(record), record)
      end

      it "is viewed as Extended JSON on one line" do
        assert_equal '{"name":"Jack","count":1}', editor.to_display_text({"name" => "Jack", "count" => 1})
      end

      it "raises for text that is not valid JSON" do
        assert_raises(JSON::ParserError) { editor.from_text("{oops", {"name" => "Jack"}) }
      end
    end
  end
end
