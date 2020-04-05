Rails.application.config.assets.precompile << proc do |path|
  true if path =~ /\.(eot|svg|ttf|woff)\z/
end

Rails.application.config.assets.precompile += %w[
  rocket_job_mission_control/favicon.png
  rocket_job_mission_control/safari-pinned-tab.svg
  rocket_job_mission_control/favicon-16x16.png
  rocket_job_mission_control/favicon-32x32.png
  rocket_job_mission_control/apple-touch-icon.png
]
