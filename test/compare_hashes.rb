def compare_array_of_hashes(expected, actual)
  expected.each_with_index do |expected_hash, index|
    compare_hash(expected_hash, actual[index])
  end
end

def compare_hash(expected_hash, actual_hash)
  expected_hash.each_pair do |key, expected|
    actual = actual_hash[key]
    if expected.is_a?(Regexp)
      assert_match expected, actual, "#{key} does not match. Expected #{expected.inspect}. Actual #{actual.inspect}"
    else
      assert_equal expected, actual, "#{key} not equal. Expected #{expected.inspect}. Actual #{actual.inspect}"
    end
  end
end

