Rails.application.config.assets.paths << Rails.root.join("app", "assets", "fonts")
Rails.application.config.assets.precompile << ["*.svg", "*.eot", "*.woff", "*.ttf"]
Rails.application.config.assets.precompile += %w[
  rocketjob_mission_control/application.css
  rocketjob_mission_control/application.js
  rocketjob_mission_control/favicon.png
  rocketjob_mission_control/safari-pinned-tab.svg
  rocketjob_mission_control/favicon-16x16.png
  rocketjob_mission_control/favicon-32x32.png
  rocketjob_mission_control/apple-touch-icon.png
]
