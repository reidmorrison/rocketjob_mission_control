class JobSanitizer
  attr_reader :params

  def initialize(params)
    @params = params
  end

  def sanitize
    sanitize_log_level
    params
  end

  private
  def sanitize_log_level
    params[:job][:log_level] = nil if params[:job][:log_level].blank?
  end
end
