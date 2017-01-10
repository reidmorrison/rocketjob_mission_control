module RocketJobMissionControl
  class Query
    attr_reader :scope, :default_order
    attr_accessor :search_term, :order_by, :search_term, :start, :page_size,
      :search_columns, :display_columns

    def initialize(scope, default_order = {})
      @scope           = scope
      @order_by        = @default_order = default_order
      @search_columns  = []
      @display_columns = []
    end

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
          records = records.where('$or' => cols)
        end
      end

      # Pagination
      if start && page_size
        records = records.skip(start).limit(page_size)
      end
      records
    end

    # Returns the filtered query expression with the sort applied
    def query
      # Sort must be applied last
      order_by ? unsorted_query.sort(order_by) : unsorted_query
    end

    def count
      unsorted_query.count
    end

    def unfiltered_count
      scope.count
    end

  end
end
