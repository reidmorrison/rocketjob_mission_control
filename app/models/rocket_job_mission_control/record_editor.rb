module RocketJobMissionControl
  # Converts a failed batch record into the text that an operator views and edits, and the edited text back into a
  # record of the same kind, so that editing a record keeps its type.
  #
  # A String record is shown as its text, with each unprintable or invalid byte escaped, see RecordEscaper. Any other
  # record, such as a Hash or an Array uploaded in :hash or :array mode, or the [first, last] range of an integer range
  # upload, is shown as MongoDB Extended JSON, so that values such as a Time or a BSON::ObjectId keep their types.
  module RecordEditor
    module_function

    # Returns [String] the record as the text to edit.
    def to_text(record)
      return RecordEscaper.escape(record) if record.is_a?(String)

      JSON.pretty_generate(record.as_extended_json(mode: :relaxed))
    end

    # Returns [String] the record as the text to view on one line, see #to_text.
    def to_display_text(record)
      return record if record.is_a?(String)

      JSON.generate(record.as_extended_json(mode: :relaxed))
    end

    # Returns the record that the edited text holds, of the same kind as the record that was edited.
    #
    # Raises JSON::ParserError, or BSON::Error, when the text for a record that is not a String is not valid
    # Extended JSON.
    def from_text(text, record)
      text = text.to_s.gsub("\r\n", "\n")
      return RecordEscaper.unescape(text) if record.is_a?(String)

      BSON::ExtJSON.parse(text, mode: :bson)
    end
  end
end
