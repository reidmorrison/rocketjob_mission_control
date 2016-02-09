module RocketJobMissionControl
  class DirmonEntriesDatatable
    delegate :params,
             :link_to,
             :dirmon_entry_path,
             :state_icon,
             :render, to: :@view

    delegate :h, to: 'ERB::Util'

    def initialize(view, dirmons)
      @view = view
      @unfiltered_dirmons = dirmons
    end

    def as_json(options = {})
      {
        :draw => params[:draw].to_i,
        :recordsTotal =>  get_raw_records.count,
        :recordsFiltered => filter_records(get_raw_records).count,
        :data => data
      }
    end

    private

    def data
      dirmons.map do |dirmon|
        {
          '0' => name_with_link(dirmon),
          '1' => h(dirmon.job_class_name),
          '2' => h(dirmon.pattern.try(:truncate, 80)),
          'DT_RowClass' => "card callout callout-#{dirmon.state}"
        }
      end
    end

    def get_raw_records
      @unfiltered_dirmons
    end

    def dirmons
      @dirmons ||= fetch_dirmons
    end

    def fetch_dirmons
      records = get_raw_records
      records = sort_records(records) if params[:order].present?
      records = filter_records(records) if params[:search].present?
      records = paginate_records(records) unless params[:length].present? && params[:length] == '-1'
      records
    end

    def page
      (params[:start].to_i / per_page) + 1
    end

    def per_page
      params.fetch(:length, 10).to_i
    end

    def sort_records(records)
      sort_by = {}
      params[:order].keys.each do |key|
        sort_by[sort_column(params[:order][key][:column])] = params[:order][key][:dir]
      end
      records.sort(sort_by)
    end

    def sort_column(index)
      columns = %w[name max_threads started_at heartbeat.updated_at]
      columns[index.to_i]
    end

    def filter_records(records)
      return records unless (params[:search].present? && params[:search][:value].present?)
      conditions = params[:search][:value]#build_conditions_for(params[:search][:value])
      records = RocketJobMissionControl::DirmonEntries::Search.new(conditions, records).execute if conditions
      records
    end

    def paginate_records(records)
      Kaminari.paginate_array(records.all).page(page).per(per_page)
    end

    def name_with_link(dirmon)
      <<-EOS
        <a href="#{dirmon_entry_path(dirmon.id)}">
          <i class="fa #{state_icon(dirmon.state)}" style="font-size: 75%" title="#{dirmon.state}"></i>
          #{dirmon.name}
        </a>
      EOS
    end
  end
end
