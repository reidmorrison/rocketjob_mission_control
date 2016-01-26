module RocketJobMissionControl
  class JobsDatatable
    delegate :params, :link_to, :job_path, to: :@view
    delegate :h, to: 'ERB::Util'

    def initialize(view)
      @view = view
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
      jobs.map do |job|
        [
          link_to(job.class, job_path(job.id)),
          h(job.description.try(:truncate, 50)),
          h(job.completed_at),
          h(job.duration)
        ]
      end
    end

    def get_raw_records
      RocketJob::Job.where()
    end

    def jobs
      @jobs ||= fetch_jobs
    end

    def fetch_jobs
      records = get_raw_records
      records = sort_records(records) if params[:order].present?
      # records = filter_records(records) if params[:search].present?
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
      columns = %w[_type description completed_at duration]
      columns[index.to_i]
    end

    def filter_records(records)
      records = simple_search(records)
      # records = composite_search(records)
      records
    end

    def simple_search(records)
      return records unless (params[:search].present? && params[:search][:value].present?)
      conditions = build_conditions_for(params[:search][:value])
      records = records.where(conditions) if conditions
      records
    end

    # def composite_search(records)
    #   conditions = aggregate_query
    #   records = records.where(conditions) if conditions
    #   records
    # end

    def paginate_records(records)
      Kaminari.paginate_array(records.all).page(page).per(per_page)
    end


  end
end

# Class
# Description
# Completion
# Duration
#
# User.page(7).per(50)
