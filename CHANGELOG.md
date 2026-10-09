# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Breaking changes

- Depend on `rocketjob` ~> 7.1, which requires IOStreams 3.0.
- Replicating a Dirmon entry creates a pending entry. Previously the copy kept the state of the
  original, and why it failed.

### Security

- Paths are shown without the user name, password or query of a url, such as
  `sftp://user:password@host/file.csv`: the upload file name on the job details page, the job's
  path and url attributes, such as the `source_url` and `target_url` of a `CopyFileJob`, the secrets in
  a `CopyFileJob`'s arguments and streams, such as an SFTP password or PGP passphrase, the paths in an
  `UploadFileJob`'s properties, the file name of each input and output category, and a Dirmon entry's
  pattern, archive directory and the paths in its properties, on its details page and in the Dirmon
  entries list. A value
  that is not a valid path is shown as `(not a valid path)`. The edit and copy forms still show the
  full value, so that it can be changed.

### New features

- A Dirmon entry whose storage, such as an SFTP server, cannot be reached shows when it became
  unavailable. Rocket Job scans such an entry again on each run, and only fails it once its storage
  has been unavailable for an hour, so until then it is still shown as enabled.

### Fixes

- Editing a record of a failed slice only changes that record, and keeps its type. Previously every
  record of the slice was saved as text, so a Hash or Array record, such as one uploaded in `:hash` or
  `:array` mode, or the range of an integer range upload, became the text of its Ruby `inspect`, such as
  `{"name" => "Jack"}`, which the job then could not process. A record that is not text is now shown,
  and edited, as MongoDB Extended JSON, so that values such as a time keep their types.
- Deleting a record of a failed slice only removes that record. Previously it removed every record in
  the slice that was equal to it.
- The log entry for an edited or deleted record shows the job's upload file name without any credentials.
- Replicating a Dirmon entry no longer copies when the storage of the original became unavailable,
  which could fail the copy before its own storage had been unavailable for an hour.
- Remove a Ruby 4.0 frozen string literal warning when listing stopping servers.

## [7.0.0] 2026-09-05

### Breaking changes

- Depend on `rocketjob` ~> 7.0.
- Raise the minimum dependency versions: Ruby 3.2, Rails/`railties` 7.2.
- Replace Bootstrap 3.4.1 (EOL, unpatched carousel XSS CVE-2024-6484) with Bootstrap
  5.3.3. The layout, navbar, panels (now cards), forms, buttons, and utility classes
  were all ported to BS5 markup; the custom BS3 `row-offcanvas` sidebar and Glyphicons
  were dropped. Host apps with custom CSS targeting the old BS3 classes will need to
  update them.
- Replace rails-ujs with Turbo Drive. Every job/server/dirmon action link (pause,
  resume, abort, fail, retry, run_now, destroy, enable, disable, copy, replicate, stop)
  now uses `data-turbo-method`/`data-turbo-confirm` instead of `data-method`/
  `data-confirm`. Redirects following these actions now respond `303 See Other` so the
  browser doesn't replay a non-GET verb against the redirect target.
- Replace Selectize with tom-select. The `.selectize` CSS class is now `.tom-select`;
  host apps with custom styling targeting the old class will need to update it.
- Rebuild the vendored DataTables bundle on 2.3.8 with Bootstrap 5 styling, dropping
  JSZip, pdfmake, the Flash export button, and every other unused extension.
- Upgrade Font Awesome 5.0.6 -> 7.3.0. FA7 keeps every FA5 icon name as an alias, so
  existing `fas fa-*` classes continue to resolve.
- Drop the Sprockets `//= require` asset bundles (`application.css`/`application.js`)
  in favor of individually linked vendored files, for Propshaft compatibility. Verified
  end-to-end against the Sprockets-based dummy app; not yet verified against a real
  Propshaft host app.

### New features

- Support Rails 8.0 and 8.1, and Mongoid 9.1.
- Add a cosmic dark theme (navbar banner, links/buttons, state colors) across every
  page, including the sidebar and category/slice/exception views.
- Show the reason a job is throttled: the triggered throttle's `description:` is
  surfaced via new `throttled_by`/`throttled_at` fields on jobs.
- Make the access policy class configurable via
  `Config.access_policy_class` (a Class, or a String/Symbol that is constantized).
- Add a progress bar for batch job slices.
- Render Array/Hash job fields as a collapsible JSON tree instead of a flat dump.
- Add a "Show Workers" button to the batch job view.
- Improve failed batch record inspection and repair, including returning to the
  edited slice after saving or deleting a record.
- Add a Capybara + Cuprite system test suite (driven by the same vendored-Chrome
  binary used for manual visual verification) covering the job/server/dirmon action
  links end to end; this is the only test coverage that exercises the vendored JS
  (Turbo, DataTables, tom-select).

### Fixes

- Fix reflected XSS in flash messages: the flash partial no longer calls `html_safe`,
  so messages are auto-escaped and call sites no longer need to sanitize interpolated
  values themselves.
- Fix job edit forms discarding user input on a validation error; the form now
  re-renders with the submitted values alongside the error messages.
- Fix a Zeitwerk eager-load failure for `CSVJob` under CI.
- Fix numerous Bootstrap 5 migration regressions: zebra striping on list tables,
  DataTables toolbar whitespace, sidebar link stacking, detail-page section spacing,
  narrow content width, DataTable row stacking, and server collection-action buttons
  disappearing under DataTables 2.x.

### Documentation

- Add `CLAUDE.md`; refresh the README and drop references to the now-defunct
  `rocketjob_pro`/`rocketjob_enterprise` gems (their functionality moved into
  `rocketjob` itself).
- Document the headless-Chrome / Puppeteer visual verification workflow used to catch
  CSS/markup regressions that the test suite can't see.
- Point the gemspec URLs, the navbar brand link, and every documentation link at
  `https://rocketjob.reidmorrison.com/`; the Rocket Job documentation site has moved
  from `rocketjob.io`.

### Internal

- Raise test coverage from 89.1% to 95.9% (SimpleCov); add Solargraph for development.
- Enforce RuboCop in CI and apply safe and reviewed-unsafe autocorrections.
- Remove dead code: an unused datatable duration column and an unrouted dirmon action.
- Bump `actions/checkout` 4 -> 7 and `browser-actions/setup-chrome` 1 -> 2; add
  bundler-audit to CI.
- Expand the dummy app's seed data to exercise every Mission Control view, including
  large/nested Array and Hash fields, and make seeding idempotent.

## [6.0.6] 2021-11-30

- Use the fully qualified `RocketJobMissionControl::AccessPolicy` class name.

## [6.0.5] 2021-11-10

- Remove blank entries from Rails-converted arrays when using multi-select input.

## [6.0.4] 2021-11-04

- Make Dirmon Entry pages consistent with the Jobs pages.

## [6.0.3] 2021-10-12

- Fix duplicate screen elements in the datatable.
- Fix Array-type field handling (part 2).

## [6.0.2] 2021-09-20

- Fix Array-type fields and DirmonEntry error handling.

## [6.0.1] 2021-09-20

- Temporarily require `jquery-rails` and `turbolinks` pending a Webpack release.

## [6.0.0] 2021-08-25

- Upgrade Bootstrap to 3.4.1 (XSS fix) and jQuery 1 -> 3.5.1; drop `jquery-rails`.
- Fix reflected XSS: flash messages no longer output unsanitized `params[:id]`.
- Fix an XSS warning on the Dirmon Entry Name field.
- Use Amazing Print to render arbitrary field types.
- Allow non-authorized Rocket Job apps to edit jobs.
- Set the minimum supported Ruby version.

## [6.0.0.beta] 2021-06-30

- Support Rocket Job v6.
- Add cascading input/output category fields, including editing categories on Dirmon
  Entries.
- Move CI to GitHub Actions; change the `rails` dependency to `railties`.

## [5.0.1] 2021-02-03

- Support Rails 6.1 and Ruby 3.
- Switch to Amazing Print.
- Switch to a Mongoid patch against 7.2 instead of head.

## [5.0.0] 2020-05-07

- Upgrade to Rocket Job 5.2.0.
- Remove the `jquery-datatables-rails` dependency; vendor static JS/CSS assets.
- Add the ability to create a new Dirmon Entry from an existing instance.

## [5.0.0.beta1] 2020-04-05

- Add Rails 6 support, drop Rails 4.
- Slices now report `processing_record_number` (Rocket Job 5.2).
- Use events for managing individual servers.

## [4.3.0] 2020-01-15

- Use events for managing servers.
- Remove the `bootstrap-sass` dependency; vendor Bootstrap instead.

## [4.2.1] 2019-10-27

- Support Rocket Job v5.
- Update `bootstrap-sass` to fix an asset compile issue.

## [4.2.0] 2019-04-03

- Add a `record_count` column to the Running and Queued views.
- Fix test failures after a Rocket Job zombie-handling change.

## [4.1.0] 2019-02-08

- Add slice record editing: per-record edit buttons, line numbering, and a
  delete-line action.
- Add roles and RBAC fixes.
- Various UI, pagination, and flash-message fixes.

## [4.0.0] 2018-11-19

- Upgrade to Rocket Job v4.
- Only show the pause action when a job is pausable.

## [3.2.0] 2018-08-15

- Display jobs in the order they will be processed, most recent first.
- Prevent throttled jobs from displaying.
- Add access-policy role inheritance (`inherit_less_privilege_roles`).
- Convert to Font Awesome v5 and vendor its assets instead of using a CDN.

## [3.0.3] 2017-07-13

- Fix leaving out `false` values when showing a job or dirmon entry.

## [3.0.2] 2017-06-01

- Fix Dirmon Entry pattern updates not saving.
- Require Bootstrap's JS collapse plugin so the mobile menu works.

## [3.0.1] 2017-03-07

- Use Appraisal to manage Gemfiles across Rails/Mongoid versions.

## [3.0.0] 2017-03-02

- Convert views from Haml to ERB.
- Replace RSpec with Minitest across controllers, models, and helpers.
- Replace the dummy Rails app with a usable standalone app.

## [3.0.0.rc1] 2017-01-11

- Migrate to Mongoid.
- Rename Workers to Servers; adopt the new Server/ActiveWorker classes.
- Refactor queries and datatables.

## [2.1.1] 2016-07-06

- Escape search input strings (regex injection fix).
- Various Rails 4/5 compatibility fixes.

## [2.1.0] 2016-05-17

- Add an edit page for jobs, and action buttons on job listings.
- Add filter-controller tests for jobs, dirmon entries, and workers.

## [2.0.0] 2016-02-27

- Minor fixes following the 2.0.0 release candidates.

## [2.0.0.rc2] 2016-02-16

- Add a "run now" action for scheduled jobs.

## [2.0.0.rc1] 2016-02-15

- Support Rocket Job v2.
- Rewrite views on server-side DataTables (search/sort/pagination); add a sidebar,
  state icons, and split active-worker views by state.
- Add Hash property support; support JRuby tests.

## [1.2.4] 2015-10-25

- Remove Rocket Job Pro dependencies.
- Keep form params when loading dirmon properties.

## [1.2.3] 2015-10-14

- Fix selective JS issues.

## [1.2.2] 2015-09-28

- Support dynamic job/dirmon-entry properties based on job class and perform method.
- Only show slice failures if they exist.
- Allow Mission Control to work without `rails_semantic_logger`.

## [1.2.1] 2015-08-27

- Add a failures view with stack traces and pagination.
- Add zombie-worker styling and a `destroy_zombies` action; display last heartbeat.
- Add DirmonEntry `perform_method`/`archive_directory` fields; fix enable/disable
  state transitions.
- Add flash messages and confirmation prompts for state-change actions.

## [1.1.0] 2015-08-02

- Add the initial Dirmon UI.

## [1.0.0] 2015-07-30

- Initial release.
