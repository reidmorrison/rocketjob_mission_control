# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`rocketjob_mission_control` is a **mountable Rails Engine** (namespace `RocketJobMissionControl`) that provides the web UI for managing [Rocket Job](http://rocketjob.io). It is packaged as a gem and mounted into a host Rails app via `mount RocketJobMissionControl::Engine => 'rocketjob'`. Data is persisted in MongoDB through Mongoid; the engine reads and mutates `RocketJob::Job`, `RocketJob::Server`, `RocketJob::Worker`, and `RocketJob::DirmonEntry` documents. It defines no database tables of its own.

## Sister projects (local checkouts)

RJMC is one of a family of gems by the same author, all checked out one directory up (`../`). When a change touches one of these dependencies, read its source directly rather than the installed gem:

- `../rocketjob`: the batch job engine RJMC manages (`RocketJob::Job`, `Server`, `Worker`, `DirmonEntry`).
- `../semantic_logger`, `../rails_semantic_logger`: logging (`JobsController#error_occurred` special-cases `SemanticLogger::Logger`).
- `../iostreams`: streaming file I/O used by Rocket Job batch jobs.
- `../symmetric-encryption`: encryption used for encrypted slices/fields.

Rocket Job Pro and Enterprise functionality has been rolled into `rocketjob` itself; there are no separate `rocketjob_pro` / `rocketjob_enterprise` gems. To develop against a local copy of any dependency, point `rjmc/Gemfile` at `path: "../<gem>"`.

## Commands

Testing uses [Appraisal](https://github.com/thoughtbot/appraisal) to run against multiple Rails/Mongoid combinations (see `Appraisals`: rails_7.2, rails_8.0, rails_8.1). Gems install into the global gem list.

```bash
bundle install
appraisal install                     # generate gemfiles/*.gemfile, install using existing *.lock
appraisal update                      # re-resolve every appraisal to latest allowed versions, regenerate *.lock

bundle exec rake                      # run tests against ALL appraisals (default task)
appraisal rails_8.1 rake              # run tests for one Rails version

# single test file / single test case (must run under an appraisal)
appraisal rails_8.1 ruby -I'test' test/controllers/rocket_job_mission_control/jobs_controller_test.rb
appraisal rails_8.1 ruby -I'test' test/controllers/rocket_job_mission_control/jobs_controller_test.rb -n "/PATCH #update/"

bundle exec rubocop                   # lint
```

After changing gemspec/Gemfile dependencies (e.g. adding a gem), run `bundle update` then `appraisal update` so both the root lock and every `gemfiles/*.gemfile.lock` pick up the change; `appraisal install` alone will reuse stale appraisal locks.

Note: `bundle exec rake` with no `APPRAISAL_INITIALIZED`/`TRAVIS` env var runs `app:appraisal`, iterating every appraisal. Set `APPRAISAL_INITIALIZED=1` (or run inside `appraisal <name>`) to run the plain `test` task once.

CI (`.github/workflows/ci.yml`) runs the same appraisals on GitHub Actions with a MongoDB service container: Rails 7.2 on Ruby 3.2, Rails 8.0 on Ruby 3.4, Rails 8.1 on Ruby 4.0.

### Dummy app (`rjmc/`)

`rjmc/` is a full dummy Rails app used both as the test harness (`test/test_helper.rb` boots `rjmc/config/environment`) and for running RJMC standalone during development.

```bash
cd rjmc
bundle
bin/rake db:seed        # seed jobs in various states (run repeatedly for more data)
bin/rails s             # start the web UI
bin/rails c             # console
bin/rocketjob           # start a Rocket Job server with 10 workers (processes queued jobs)
```

To develop against a local checkout of Rocket Job, edit `rjmc/Gemfile` to point `rocketjob` at `path:` instead of `github:`. Seed jobs `AllTypesJob`, `CSVJob`, `KaboomBatchJob` live in the dummy app for DirmonEntry / batch / error-path testing.

## Architecture

### Request flow: DataTables + AJAX

The four resources (jobs, servers, active_workers, dirmon_entries) all render server-side [DataTables](https://datatables.net). Each state view (running/paused/failed/etc.) renders an HTML shell, then the browser issues a JSON request back to the same action (`format: "json"`). The JSON branch is served by a **Datatable** object in `app/datatables/`:

- `AbstractDatatable` (`as_json`) produces the `{draw, recordsTotal, recordsFiltered, data}` payload DataTables expects, and translates DataTables request params (search value, column ordering, `start`/`length` pagination) into a `Query`.
- Concrete datatables (`jobs_datatable.rb`, etc.) define the column sets (e.g. `JobsDatatable::RUNNING_COLUMNS`, `RUNNING_FIELDS`) and a `map(record)` that turns one Mongoid document into a table row.
- `Query` (`app/models/`) wraps a Mongoid scope and applies text search (case-insensitive regex over `search_columns`, `$or` across multiple; the search term is `Regexp.escape`d), sorting, and skip/limit pagination. `count` is post-filter, `unfiltered_count` is pre-filter.

When adding a column to a table, update both the `*_COLUMNS` (display) and `*_FIELDS` (the Mongoid `.only(...)` projection) constants, plus `map`.

### Authorization

Uses [access-granted](https://github.com/chaps-io/access-granted). Three pieces:

- `AccessPolicy` (`app/models/`) defines role → permission rules over the `RocketJob::*` classes. Roles: `admin, editor, operator, manager, dirmon, user, view`. The policy class is overridable per host via `Config.access_policy_class` (a Class, or a String/Symbol that is constantized).
- `Authorization` (`app/models/`) is the "current user" object. Roles are **hierarchical**: constructing it with a role also grants all lower-privilege roles (`inherit_less_privilege_roles`, ordering defined by `ROLES`). The `user` role is scoped so a user may only act on jobs whose `login` matches.
- `ApplicationController#current_policy` builds the policy from `Config.authorization_callback`. The host app sets this callback (via `config.rocket_job_mission_control.authorization_callback`) returning `{roles:, login:}`. **When no callback is configured, the default is full admin (`{roles: [:admin]}`)**: auth is opt-in by the host.

Controllers call `authorize! :action, Resource` (provided by access-granted through the policy). `AccessGranted::AccessDenied` is rescued and surfaced as a flash message.

### Parameter sanitizing for dynamic job types

Rocket Job jobs have user-defined fields, so strong-params lists are computed at runtime, not hardcoded:

- `JobsController#job_fields` / `job_params` build permitted params from `job_class.user_editable_fields` and each field's Mongoid type (Array fields permit arrays).
- `JobSanitizer` / `DirmonSanitizer` (`app/models/`) coerce submitted values by field type: normalize CRLF in Strings, `JSON.parse` Hash fields (adding a model error on parse failure), strip blanks from multi-select Arrays, and null-out blanks. They also fold `input_categories_attributes` / `output_categories_attributes` (batch job I/O category nested forms) into `input_categories` / `output_categories`.

### Routing

`config/routes.rb` roots at `jobs#running`. Each resource exposes one collection action per lifecycle state (jobs: running/scheduled/completed/queued/paused/failed/aborted) plus member actions for state transitions (`abort`, `fail`, `pause`, `resume`, `retry`, `run_now` for jobs; `stop`/`pause`/`resume` for servers; `enable`/`disable`/`copy`/`replicate` for dirmon entries). The `running` jobs action deliberately filters out just-started jobs (`started_at <= now - 0.1`) to hide throttled jobs.

### Engine wiring

`lib/rocket_job_mission_control/engine.rb` `isolate_namespace`s the engine, requires `rocketjob`, and exposes `config.rocket_job_mission_control` → `RocketJobMissionControl::Config` (`mattr_accessor`s: `authorization_callback`, `access_policy_class`).

### Front-end assets

All JS/CSS libraries are vendored files under `app/assets/` (no npm, importmap, or CDN). Current versions: jQuery 3.7.1, Bootstrap 3.4.1, a DataTables 2.3.8 downloader bundle with Bootstrap 3 styling and the Responsive 3.0.8 extension only (`responsive: true` is the sole extension the app uses; rebuild it via the datatables.net download builder URL in the file header, e.g. the `/v/bs/dt-2.3.8/r-3.0.8/` combined CDN path), Selectize 0.12.4, jquery.json-viewer 1.5.0 (vendored verbatim; upgrade by replacing the file, theming lives in `json_tree.css`), and Font Awesome 5.0.6.

The pipeline is Sprockets-only: `application.js` is a `//= require` manifest (including `rails-ujs`, which powers every `data-method` state-transition link), and several stylesheets are `.css.erb` using `asset_path`. Host apps on Rails 8+ default to Propshaft and must add `sprockets-rails` to use this engine.

## Security-sensitive rendering paths

- The flash partial (`app/views/layouts/rocket_job_mission_control/partials/_flash.html.erb`) renders every message with `html_safe`. Anything interpolated into `flash[...]` (params, exception messages, job data) must be escaped or sanitized at the call site, or it is an XSS vector. There is prior history here: commit 3dee9b6 fixed a reflected XSS from unsanitized `params[:id]` in flash messages.
- Datatable `map` methods build HTML strings by hand; every dynamic cell value must go through `h(...)` (`AbstractDatatable` delegates `h` to `ERB::Util`) because DataTables renders cells as raw HTML.
- Several `rescue_from` handlers start with `raise exception if Rails.env.development? || Rails.env.test?`, so their recovery branches only ever execute in production and are invisible to the test suite. Treat changes to those branches as untested until exercised manually.

## Known tech debt (modernization review, July 2026)

Remove items from this list as they are fixed:

1. Bootstrap 3.4.1 is EOL with an unpatched XSS CVE (CVE-2024-6484, carousel; unused here). The big-ticket project: migrate to Bootstrap 5, Propshaft-compatible assets (plain CSS `url()` instead of `.css.erb`), Turbo-friendly action links instead of rails-ujs `data-method`, tom-select instead of Selectize, Font Awesome 6.
2. Housekeeping is done (`feature/ci-housekeeping`, PR #108): gemspec `s.test_files` removed; CI on `actions/checkout@v4`; RuboCop, bundler-audit, and dependabot all wired into CI; `.rubocop.yml` `TargetRubyVersion` at 3.2.

Fixed in `feature/modernize-vendored-js` (was item 1): the DataTables bundle was rebuilt on 2.3.8 with only Bootstrap 3 styling and Responsive 3.0.8, dropping JSZip, pdfmake, the Flash export button, and every other unused extension (all CVE-bearing pieces were in the dropped set); jQuery bumped 3.5.1 → 3.7.1. The JS bundle shrank from 2.2 MB to ~118 KB.

Fixed in `feature/modernize-security-quick-wins`: reflected XSS in flash messages (the flash partial no longer calls `html_safe`, so all messages are auto-escaped and no call site needs to sanitize); `redirect_to :back` replaced with `redirect_back(fallback_location:)` in the jobs/servers/dirmon rescue paths; dead `Rails.version.to_i < 5` / `before_filter` branches removed; `update_attributes` replaced with `update`.

## Conventions

- Ruby >= 3.2 required. RuboCop enforces trailing dot position, `lf` line endings, and table-aligned hashes; match the heavy column alignment already used throughout the codebase.
- Tests are Minitest via `minispec-rails`; controller tests include the engine's route helpers and set `@routes = RocketJobMissionControl::Engine.routes`.
- Gem version lives in `lib/rocket_job_mission_control/version.rb`.
- Per the global writing-style rule, avoid em dashes in prose and comments.
