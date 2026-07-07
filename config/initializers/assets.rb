Rails.application.config.assets.precompile << ["*.svg", "*.eot", "*.woff", "*.ttf"]
Rails.application.config.assets.precompile += %w[
  rocket_job_mission_control/favicon.png
  rocket_job_mission_control/safari-pinned-tab.svg
  rocket_job_mission_control/favicon-16x16.png
  rocket_job_mission_control/favicon-32x32.png
  rocket_job_mission_control/apple-touch-icon.png
]
# The layout links each vendored CSS/JS file individually (no more bundled
# application.css/js), so each one needs its own entry here -- Sprockets'
# runtime "was this precompiled?" check (unlike the assets:precompile rake
# task) looks up exact logical paths one at a time and doesn't consult
# manifest.js's link_directory globs.
Rails.application.config.assets.precompile += %w[
  rocket_job_mission_control/bootstrap.min.css
  rocket_job_mission_control/fontawesome-all.min.css
  rocket_job_mission_control/tom-select.default.min.css
  rocket_job_mission_control/datatables.min.css
  rocket_job_mission_control/base.css
  rocket_job_mission_control/syntax_highlighting.css
  rocket_job_mission_control/json_tree.css
  rocket_job_mission_control/callout.css
  rocket_job_mission_control/jobs.css
  rocket_job_mission_control/worker_processes.css
  rocket_job_mission_control/jquery-3.7.1.min.js
  rocket_job_mission_control/turbo.min.js
  rocket_job_mission_control/datatables.min.js
  rocket_job_mission_control/datatable_init.js
  rocket_job_mission_control/bootstrap.bundle.min.js
  rocket_job_mission_control/dirmon_entries.js
  rocket_job_mission_control/tom-select.complete.min.js
  rocket_job_mission_control/tom_select_init.js
  rocket_job_mission_control/jquery.json-viewer.js
  rocket_job_mission_control/json_tree_init.js
  rocket_job_mission_control/backtrace.js
]
