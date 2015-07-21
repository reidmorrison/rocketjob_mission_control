# Rocket Job Mission Control[![Build Status](https://secure.travis-ci.org/rocketjob/rocketjob_mission_control.png?branch=master)](http://travis-ci.org/rocketjob/rocketjob_mission_control) ![](http://ruby-gem-downloads-badge.herokuapp.com/rocketjob_mission_control)

The UI for [rocketjob][0].
This gem is written to work with rails 4 applications using
activerecord.

Some features:

* Easily view jobs enqueued, working, pending, and failed.
* Queue any single job. or all pending jobs, to run immediately.
* Remove a failed job, or easily remove all failed jobs.

The interface:

![Screen shot](https://dl.dropboxusercontent.com/u/18805203/rjmc-home.png)


Quick Start For Rails 4 Applications
------------------------------------

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

Contributing
------------

1. Fork
2. Hack
3. `rake spec`
4. Send a pull request


Releasing a new version
-----------------------

1. Update the version in `lib/rocket_job_mission_control/version.rb`
2. `lib/rocket_job_mission_control/version.rb` with the following message format:

        Version x.x.x

        Changelog:
        * Some new feature
        * Some new bug fix
3. `rake release`


Authors
------

* Michael Cloutier - [mjcloutier][1]
* Chris Lamb - [lambcr][2]


[0]: https://github.com/rocketjob/rocketjob
[1]: https://github.com/mjcloutier
[2]: https://github.com/lambcr
