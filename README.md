# Rocket Job Mission Control
[![Gem Version](https://img.shields.io/gem/v/rocketjob_mission_control.svg)](https://rubygems.org/gems/rocketjob_mission_control) [![Downloads](https://img.shields.io/gem/dt/rocketjob_mission_control.svg)](https://rubygems.org/gems/rocketjob_mission_control) [![License](https://img.shields.io/badge/license-Apache%202.0-brightgreen.svg)](http://opensource.org/licenses/Apache-2.0) ![](https://img.shields.io/badge/status-Production%20Ready-blue.svg) [![Gitter chat](https://img.shields.io/badge/IRC%20(gitter)-Support-brightgreen.svg)](https://gitter.im/rocketjob/support)

Web based management interface for [Rocket Job][0].

![Screen shot](http://rocketjob.io/images/rjmc_running.png)

## Status

Production Ready

Already in use in production processing large files with millions
of records, as well as large jobs to walk through large databases.

## Features

Job Management

* View all queued, running, failed, and running jobs.
* View all completed jobs where `destroy_on_complete` is `false`.
* Pause any running jobs.
* Resume paused jobs.
* Retry failed jobs.
* Abort, or fail queued or running jobs.
* Destroy a completed or aborted job.

Server Management

* View running servers.
* Stop servers.

Running Jobs

* View the jobs that workers are currently working on.

Directory Monitor Management

* Create, update, enable, disable directory monitoring entries.

## Documentation

* [Guide](http://rocketjob.io/mission_control)

## Rails Installation

This gem is a Rails Engine and can be installed directly into existing Rails 4
or 5 applications.

Add to Gemfile:

```ruby
gem 'rocketjob_mission_control'
```

Install:

```ruby
bundle
```

Add the following route to `config/routes.rb`:

```ruby
mount RocketjobMissionControl::Engine => 'rocketjob'
```

## Development and Testing

* [Development and Testing](TESTING.md) documentation.

## Versioning

This project uses [Semantic Versioning](http://semver.org/).

## Authors

* [Michael Cloutier][1]
* [Chris Lamb][2]
* [Jonathan Whittington][4]
* [Reid Morrison][3] :: @reidmorrison

[0]: http://rocketjob.io
[1]: https://github.com/mjcloutier
[2]: https://github.com/lambcr
[3]: https://github.com/reidmorrison
[4]: https://github.com/jtwhittington
