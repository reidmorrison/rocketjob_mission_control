module RocketJobMissionControl
  class AbstractDatatable
    delegate :params, :link_to, :render, to: :@view
    delegate :h, to: 'ERB::Util'

    attr_accessor :view, :query

    def initialize(view, query)
      @view  = view
      @query = query
      extract_query_params
    end

    def as_json(options = {})
      {
        draw:            params[:draw].to_i,
        recordsTotal:    query.unfiltered_count,
        recordsFiltered: query.count,
        data:            data(query.query)
      }
    end

    private

    def data(records)
      raise NotImplementedError
    end

    def extract_query_params
      # Search term
      search = params[:search]
      if search.present? && search[:value].present?
        query.search_term = search[:value] if search.present?
      end

      # Sort order
      if order_by = extract_sort(params[:order])
        query.order_by = order_by
      end

      # Pagination
      unless params[:length].present? && params[:length] == '-1'
        query.start     = params[:start].to_i
        query.page_size = params.fetch(:length, 10).to_i
      end
    end

    def extract_sort(order)
      return nil unless order.present?

      ap order
      sort_by = {}
      order.each_pair do |key, value|
        name          = query.display_columns[value[:column].to_i]
        raise(ArgumentError, "Invalid column id: #{value[:column]}. Must fit #{query.display_columns.inspect}") unless name.present?
        sort_by[name] = value[:dir]
      end
      sort_by
    end

  end
end
