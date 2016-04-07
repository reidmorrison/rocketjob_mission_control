module RocketJobMissionControl
  class JobsDatatable
    delegate :params, :link_to, :job_path, :job_icon, to: :@view
    delegate :h, to: 'ERB::Util'

    def initialize(view, jobs)
      @view = view
      @unfiltered_jobs = jobs
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
        {
          '0' => class_with_link(job),
          '1' => h(job.description.try(:truncate, 50)),
          '2' => h(job.created_at),
          '3' => h(job.duration),
          'DT_RowClass' => "card callout callout-#{job.state}"
        }
      end
    end

    def get_raw_records
      @unfiltered_jobs
    end

    def jobs
      @jobs ||= fetch_jobs
    end

    def fetch_jobs
      records = get_raw_records
      records = sort_records(records) if params[:order].present?
      records = filter_records(records) if params[:search].present?
      records = paginate_records(records) unless params[:length].present? && params[:length] == '-1'
      records
    end

    def class_with_link(job)
      <<-EOS
        <a href="#{job_path(job.id)}">
          <i class="fa #{job_icon(job)}" style="font-size: 75%" title="#{job.state}"></i>
          #{job.class.name}
        </a>
      EOS
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

    def counts
      RocketJob::Job.counts_by_state
    end

    def sort_column(index)
      columns = %w[_type description completed_at]
      columns[index.to_i]
    end

    def filter_records(records)
      return records unless (params[:search].present? && params[:search][:value].present?)
      conditions = params[:search][:value]
      records = RocketJobMissionControl::Jobs::Search.new(conditions, records).execute if conditions
      records
    end

    def paginate_records(records)
      Kaminari.paginate_array(records.all).page(page).per(per_page)
    end
  end
end
