# Rocket Job Mission Control
[![Gem Version](https://img.shields.io/gem/v/rocketjob_mission_control.svg)](https://rubygems.org/gems/rocketjob_mission_control) [![Build Status](https://github.com/reidmorrison/rocketjob_mission_control/workflows/build/badge.svg)](https://github.com/reidmorrison/rocketjob_mission_control/actions?query=workflow%3Abuild) [![Downloads](https://img.shields.io/gem/dt/rocketjob_mission_control.svg)](https://rubygems.org/gems/rocketjob_mission_control) [![License](https://img.shields.io/badge/license-Apache%202.0-brightgreen.svg)](http://opensource.org/licenses/Apache-2.0) ![](https://img.shields.io/badge/status-Production%20Ready-blue.svg)

Rocket Job Mission Control is the web based user interface for [Rocket Job](http://rocketjob.io),
Ruby's missing batch system.

![Screen shot](http://rocketjob.io/images/rjmc_running.png)

It is a mountable [Rails Engine](https://guides.rubyonrails.org/engines.html) that plugs directly
into an existing Rails application, giving operators a single place to:

1. **Manage jobs.** Watch queued, scheduled, running, paused, completed, failed, and aborted jobs in
   real time, then pause, resume, retry, abort, run, or destroy them, and inspect the exceptions and
   data of any job.
2. **Manage servers and workers.** See which servers and workers are active, what each worker is
   currently processing, and stop, pause, or resume servers.
3. **Manage directory monitoring.** Create, edit, enable, disable, copy, and replicate
   [Directory Monitor](http://rocketjob.io/dirmon.html) entries that turn arriving files into jobs.

Already in use in production processing large files with millions of records, as well as large jobs
that walk through entire databases.

## Documentation

* [Rocket Job Mission Control Guide](http://rocketjob.io/mission_control)
* [Rocket Job Guide](http://rocketjob.io)

## Install

Rocket Job Mission Control is a Rails Engine. It can be mounted into any existing Rails 7.2, 8.0, or
8.1 application backed by MongoDB (via Mongoid).

Add to the host application's `Gemfile`:

```ruby
gem 'rocketjob_mission_control'
```

Install:

```sh
bundle install
```

Mount the engine by adding the following route to `config/routes.rb`:

```ruby
mount RocketJobMissionControl::Engine => '/rocketjob'
```

Mission Control is now available at `/rocketjob`.

## Authorization

By default Mission Control grants full access to every action. To restrict access, register an
authorization callback that returns the roles (and optional `login`) for the current request:

```ruby
Rails.application.config.rocket_job_mission_control.authorization_callback = -> do
  { roles: current_user.rocket_job_roles, login: current_user.login }
end
```

Available roles are `admin`, `editor`, `operator`, `manager`, `dirmon`, `user`, and `view`. Roles
are hierarchical, so granting a higher-privilege role also grants the lower ones.

## Development and Testing

See [TESTING.md](TESTING.md) for how to set up the project, run the test suite across supported Rails
versions, and run Mission Control standalone against the bundled dummy application.

## Versioning

This project uses [Semantic Versioning](http://semver.org/).

## Authors

* [Michael Cloutier](https://github.com/mjcloutier)
* [Chris Lamb](https://github.com/lambcr)
* [Jonathan Whittington](https://github.com/jtwhittington)
* [Reid Morrison](https://github.com/reidmorrison)

[Contributors](https://github.com/reidmorrison/rocketjob_mission_control/graphs/contributors)
