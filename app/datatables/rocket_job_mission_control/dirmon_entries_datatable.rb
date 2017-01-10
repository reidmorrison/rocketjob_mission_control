module RocketJobMissionControl
  class DirmonEntriesDatatable < AbstractDatatable
    delegate :dirmon_entry_path, :state_icon, to: :@view

    def initialize(view, query)
      query.display_columns   = %w[name _type pattern]
      query.search_columns = [:job_class_name, :name, :pattern]
      super(view, query)
    end

    private

    def data(dirmons)
      dirmons.map do |dirmon|
        {
          '0'           => name_with_link(dirmon),
          '1'           => h(dirmon.job_class_name),
          '2'           => h(dirmon.pattern.try(:truncate, 80)),
          'DT_RowClass' => "card callout callout-#{dirmon.state}"
        }
      end
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
