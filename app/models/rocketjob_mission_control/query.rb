module RocketjobMissionControl
  class Query
    attr_reader :scope
    attr_accessor :search_term, :order_by, :start, :page_size,
                  :search_columns, :display_columns

    def initialize(scope, order_by = nil)
      @scope           = scope
      @order_by        = order_by
      @search_columns  = []
      @display_columns = []
    end

    # Returns the filtered query expression with the sort applied
    def query
      # Sort must be applied last
      order_by ? unsorted_query.sort(order_by) : unsorted_query
    end

    # Count after applying search_term.
    # Pagination settings do not affect this count.
    def count
      unsorted_query.count
    end

    # Count before applying search term
    # Pagination settings do not affect this count.
    def unfiltered_count
      scope.count
    end

    private

    # Returns the filtered query expression
    def unsorted_query
      records = scope
      # Text Search
      if search_term
        escaped = Regexp.escape(search_term)
        regexp  = Regexp.new(escaped, Regexp::IGNORECASE)
        if search_columns.size == 1
          records = records.where(search_columns.first => regexp)
        else
          cols    = search_columns.collect { |col| {col => regexp} }
          records = records.where("$or" => cols)
        end
      end

      # Pagination
      records = records.skip(start).limit(page_size) if start && page_size
      records
    end
  end
end
