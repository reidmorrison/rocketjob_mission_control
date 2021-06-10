module RocketjobMissionControl
  module SlicesHelper
    def display_slice_info(slice, encrypted = false)
      encrypted ? "encrypted" : pretty_print_array_or_hash(slice.to_a)
    end
  end
end
