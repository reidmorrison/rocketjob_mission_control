require_relative "../../test_helper"

class RecordEscaperTest < Minitest::Test
  describe RocketJobMissionControl::RecordEscaper do
    Escaper = RocketJobMissionControl::RecordEscaper

    describe ".escape" do
      it "leaves ordinary printable text untouched" do
        assert_equal "plain text 123", Escaper.escape("plain text 123")
      end

      it "leaves valid multibyte Unicode readable" do
        assert_equal "日本語 café", Escaper.escape("日本語 café")
      end

      it "keeps tab, newline and carriage return as-is" do
        assert_equal "a\tb\nc\rd", Escaper.escape("a\tb\nc\rd")
      end

      it "escapes control characters as \\xHH" do
        assert_equal "a\\x00b\\x1Bc\\x7F", Escaper.escape("a\x00b\x1Bc\x7F")
      end

      it "escapes a literal backslash" do
        assert_equal "a\\\\b", Escaper.escape("a\\b")
      end

      it "escapes invalid UTF-8 bytes" do
        assert_equal "x\\xA3y", Escaper.escape((+"x\xA3y").force_encoding("UTF-8"))
      end
    end

    describe ".unescape" do
      it "reverses control character escapes to the original bytes" do
        assert_equal "a\x00b\x1Bc", Escaper.unescape("a\\x00b\\x1Bc")
      end

      it "reverses an escaped backslash" do
        assert_equal "a\\b", Escaper.unescape("a\\\\b")
      end

      it "leaves an unrecognized backslash sequence verbatim" do
        assert_equal "a\\z", Escaper.unescape("a\\z")
      end
    end

    describe "round trip" do
      [
        "plain text",
        "日本語 é ok",
        "control\x00\x1B\x07\bbytes",
        "tab\tnewline\nend",
        "back\\slash",
        "del\x7Fbyte",
        (+"invalid\xA3utf8").force_encoding("UTF-8")
      ].each do |original|
        it "restores every byte of #{original.inspect}" do
          restored = Escaper.unescape(Escaper.escape(original))

          assert_equal original.b, restored.b
        end
      end
    end

    describe ".segments" do
      it "splits text and escape tokens in order" do
        assert_equal [[:text, "a"], [:escape, "\\x00"], [:text, "b"]],
                     Escaper.segments("a\x00b")
      end
    end
  end
end
