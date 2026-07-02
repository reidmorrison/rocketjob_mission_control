module RocketJobMissionControl
  # Makes the unprintable content of a failed batch record safe to display and
  # (losslessly) edit in the browser.
  #
  # A record that caused a job to fail often contains control characters (NUL,
  # ESC, backspace, ...) or, rarely, invalid UTF-8 bytes. Rendered raw these are
  # invisible in HTML and silently stripped or normalized by a textarea, so an
  # operator cannot see why the record failed and editing corrupts it.
  #
  # This escapes each such byte to a reversible `\xHH` token (and `\` to `\\`),
  # while leaving ordinary printable text, including valid multibyte Unicode, and
  # tab / newline / carriage-return untouched so normal records stay readable.
  # `unescape` reverses `escape` exactly, byte for byte.
  module RecordEscaper
    module_function

    # Control bytes left as-is: tab, line feed, carriage return. They are visible
    # whitespace a textarea handles naturally, so escaping them would only hurt
    # readability.
    KEEP_CONTROL = [0x09, 0x0A, 0x0D].freeze

    ESCAPE_TOKEN = /\A\\(?:\\|x\h{2})/.freeze

    # Returns the record split into an ordered list of [type, string] pairs where
    # type is :text for readable content and :escape for a `\xHH` / `\\` token.
    # Views build either plain text (edit) or highlighted HTML (display) from it.
    def segments(value)
      segments = []
      buffer   = +""
      flush    = lambda do
        segments << [:text, buffer.dup] unless buffer.empty?
        buffer.clear
      end

      value.to_s.each_char do |char|
        if !char.valid_encoding?
          flush.call
          char.bytes.each { |byte| segments << [:escape, format("\\x%02X", byte)] }
        elsif char == "\\"
          flush.call
          segments << [:escape, "\\\\"]
        elsif control?(char)
          flush.call
          segments << [:escape, format("\\x%02X", char.ord)]
        else
          buffer << char
        end
      end

      flush.call
      segments
    end

    # Reversible, ASCII-safe representation of the record for an edit textarea.
    def escape(value)
      segments(value).map { |_type, text| text }.join
    end

    # Reverses escape: turns `\xHH` back into its byte and `\\` back into `\`.
    # Any other backslash sequence is left verbatim (it was never produced by
    # escape, so it can only come from the user typing it). Returns UTF-8 when
    # the result is valid, otherwise the raw bytes so nothing is lost.
    def unescape(escaped)
      bytes = +"".b
      chars = escaped.to_s.chars
      index = 0

      while index < chars.length
        char = chars[index]
        if char == "\\" && chars[index + 1] == "\\"
          bytes << 0x5C
          index += 2
        elsif char == "\\" && chars[index + 1] == "x" && "#{chars[index + 2]}#{chars[index + 3]}".match?(/\A\h{2}\z/)
          bytes << "#{chars[index + 2]}#{chars[index + 3]}".to_i(16)
          index += 4
        else
          bytes << char.b
          index += 1
        end
      end

      utf8 = bytes.dup.force_encoding("UTF-8")
      utf8.valid_encoding? ? utf8 : bytes
    end

    def control?(char)
      char.bytesize == 1 && ((ord = char.ord) < 0x20 || ord == 0x7F) && !KEEP_CONTROL.include?(ord)
    end
    private_class_method :control?
  end
end
