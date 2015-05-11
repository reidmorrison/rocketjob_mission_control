class JobSerializer < ActiveModel::Serializer
  attributes :id, :description, :created_at, :destroy_on_complete, :exception,
             :failure_count, :klass, :percent_complete, :perform_method,
             :priority, :repeatable, :result, :state, :duration, :url, :title

  def url
    RocketJobMissionControl.railtie_routes_url_helpers.job_path(id)
  end

  def title
    perform_method = perform_method == :perform ? '' : "##{self.perform_method}"
    "#{priority} - #{klass}#{perform_method}"
  end
end
