# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`rocketjob_mission_control` is a **mountable Rails Engine** (namespace `RocketJobMissionControl`) that provides the web UI for managing [Rocket Job](http://rocketjob.io). It is packaged as a gem and mounted into a host Rails app via `mount RocketJobMissionControl::Engine => 'rocketjob'`. Data is persisted in MongoDB through Mongoid; the engine reads and mutates `RocketJob::Job`, `RocketJob::Server`, `RocketJob::Worker`, and `RocketJob::DirmonEntry` documents. It defines no database tables of its own.

## Sister projects (local checkouts)

RJMC is one of a family of gems by the same author, all checked out one directory up (`../`). When a change touches one of these dependencies, read its source directly rather than the installed gem:

- `../rocketjob` — the batch job engine RJMC manages (`RocketJob::Job`, `Server`, `Worker`, `DirmonEntry`).
- `../semantic_logger`, `../rails_semantic_logger` — logging (`JobsController#error_occurred` special-cases `SemanticLogger::Logger`).
- `../iostreams` — streaming file I/O used by Rocket Job batch jobs.
- `../symmetric-encryption` — encryption used for encrypted slices/fields.

Rocket Job Pro and Enterprise functionality has been rolled into `rocketjob` itself; there are no separate `rocketjob_pro` / `rocketjob_enterprise` gems. To develop against a local copy of any dependency, point `rjmc/Gemfile` at `path: "../<gem>"`.

## Commands

Testing uses [Appraisal](https://github.com/thoughtbot/appraisal) to run against multiple Rails/Mongoid combinations (see `Appraisals`: rails_7.2, rails_8.0, rails_8.1). Gems install into the global gem list.

```bash
bundle install
appraisal install                     # generate/install gemfiles/*.gemfile

bundle exec rake                      # run tests against ALL appraisals (default task)
appraisal rails_8.1 rake              # run tests for one Rails version

# single test file / single test case (must run under an appraisal)
appraisal rails_8.1 ruby -I'test' test/controllers/rocket_job_mission_control/jobs_controller_test.rb
appraisal rails_8.1 ruby -I'test' test/controllers/rocket_job_mission_control/jobs_controller_test.rb -n "/PATCH #update/"

bundle exec rubocop                   # lint
```

Note: `bundle exec rake` with no `APPRAISAL_INITIALIZED`/`TRAVIS` env var runs `app:appraisal`, iterating every appraisal. Set `APPRAISAL_INITIALIZED=1` (or run inside `appraisal <name>`) to run the plain `test` task once.

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
- `Query` (`app/models/`) wraps a Mongoid scope and applies text search (case-insensitive regex over `search_columns`, `$or` across multiple), sorting, and skip/limit pagination. `count` is post-filter, `unfiltered_count` is pre-filter.

When adding a column to a table, update both the `*_COLUMNS` (display) and `*_FIELDS` (the Mongoid `.only(...)` projection) constants, plus `map`.

### Authorization

Uses [access-granted](https://github.com/chaps-io/access-granted). Three pieces:

- `AccessPolicy` (`app/models/`) defines role → permission rules over the `RocketJob::*` classes. Roles: `admin, editor, operator, manager, dirmon, user, view`.
- `Authorization` (`app/models/`) is the "current user" object. Roles are **hierarchical**: constructing it with a role also grants all lower-privilege roles (`inherit_less_privilege_roles`, ordering defined by `ROLES`). The `user` role is scoped so a user may only act on jobs whose `login` matches.
- `ApplicationController#current_policy` builds the policy from `Config.authorization_callback`. The host app sets this callback (via `config.rocket_job_mission_control.authorization_callback`) returning `{roles:, login:}`. **When no callback is configured, the default is full admin (`{roles: [:admin]}`)** — auth is opt-in by the host.

Controllers call `authorize! :action, Resource` (provided by access-granted through the policy). `AccessGranted::AccessDenied` is rescued and surfaced as a flash message.

### Parameter sanitizing for dynamic job types

Rocket Job jobs have user-defined fields, so strong-params lists are computed at runtime, not hardcoded:

- `JobsController#job_fields` / `job_params` build permitted params from `job_class.user_editable_fields` and each field's Mongoid type (Array fields permit arrays).
- `JobSanitizer` / `DirmonSanitizer` (`app/models/`) coerce submitted values by field type: normalize CRLF in Strings, `JSON.parse` Hash fields (adding a model error on parse failure), strip blanks from multi-select Arrays, and null-out blanks. They also fold `input_categories_attributes` / `output_categories_attributes` (batch job I/O category nested forms) into `input_categories` / `output_categories`.

### Routing

`config/routes.rb` roots at `jobs#running`. Each resource exposes one collection action per lifecycle state (jobs: running/scheduled/completed/queued/paused/failed/aborted) plus member actions for state transitions (`abort`, `fail`, `pause`, `resume`, `retry`, `run_now` for jobs; `stop`/`pause`/`resume` for servers; `enable`/`disable`/`copy`/`replicate` for dirmon entries). The `running` jobs action deliberately filters out just-started jobs (`started_at <= now - 0.1`) to hide throttled jobs.

### Engine wiring

`lib/rocket_job_mission_control/engine.rb` `isolate_namespace`s the engine, requires `rocketjob`, and exposes `config.rocket_job_mission_control` → `RocketJobMissionControl::Config` (`mattr_accessor :authorization_callback`). Assets are Sprockets-based.

## Conventions

- Ruby >= 3.2 required (`.rubocop.yml` still targets 2.4 for style only). RuboCop enforces trailing dot position, `lf` line endings, and table-aligned hashes — match the heavy column alignment already used throughout the codebase.
- Tests are Minitest via `minispec-rails`; controller tests include the engine's route helpers and set `@routes = RocketJobMissionControl::Engine.routes`.
- Per the global writing-style rule, avoid em dashes in prose and comments.
