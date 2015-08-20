# rocketjob mission control
[![Gem Version](https://badge.fury.io/rb/rocketjob_mission_control.svg)](http://badge.fury.io/rb/rocketjob_mission_control) [![Build Status](https://secure.travis-ci.org/rocketjob/rocketjob_mission_control.png?branch=master)](http://travis-ci.org/rocketjob/rocketjob_mission_control) ![](http://ruby-gem-downloads-badge.herokuapp.com/rocketjob_mission_control)

Web based management interface for [rocketjob][0].

![Screen shot](http://rocketjob.io/images/rjmc.png)

## Status

Production Ready

Already in use in production processing large files with millions
of records, as well as large jobs to walk though large databases.

## Features

Job Management

* View all queued, running, failed, and running jobs
* View all completed jobs where `destroy_on_complete == false`
* Pause any running jobs
* Resume paused jobs
* Retry failed jobs
* Abort, or fail queued or running jobs
* Destroy a completed or aborted job

Worker Management

* View running workers
* Stop workers

Running Jobs

* View the jobs that workers are currently working on.

Directory Monitor Management

* Create, update, enable, disable directory monitoring entries

## Documentation

* [Guide](http://rocketjob.io/mission_control)

## Rails 4 Installation

This gem is a Rails Engine and can be installed directly into existing Rails 4
applications.

Add the dependency to your Gemfile

```ruby
gem 'rocketjob_mission_control'
```

Install it...

```ruby
bundle
```

Add the following route to your application for accessing the interface,
and retrying failed jobs.

```ruby
mount RocketJobMissionControl::Engine => 'rocketjob'
```

## Versioning

This project uses [Semantic Versioning](http://semver.org/).

## Authors

* [Michael Cloutier][1]
* [Chris Lamb][2]

## Contributors

* [Reid Morrison][3] :: @reidmorrison
* [Rafi](http://www.graphicsfuel.com/2012/02/space-rocket-icon-psd/)

[0]: http://rocketjob.io
[1]: https://github.com/mjcloutier
[2]: https://github.com/lambcr
[3]: https://github.com/reidmorrison
