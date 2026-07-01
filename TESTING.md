## Installation

Install required gems

    bundle install
    
Install all needed gems to run the tests:

    appraisal install

The gems are installed into the global gem list.
The Gemfiles in the `gemfiles` folder are also re-generated.

## Run Tests

For all supported Rails/ActiveRecord versions:

    bundle exec rake

Or for specific rails version:

    appraisal rails_4.2 rake

Or for one particular test file:

    appraisal rails_5.0 ruby -I'test' test/controllers/rocket_job_mission_control/jobs_controller_test.rb

Or down to one test case:

    appraisal rails_5.0 ruby -I'test' test/controllers/rocket_job_mission_control/jobs_controller_test.rb -n "/PATCH #update/"

## Running RJMC (Rocket Job Mission Control) Standalone

Under the rocketjob_mission_control installation directory there is another directory called `rjmc`
that includes a dummy Rails application.

    cd rjmc
    
Run bundler to install the gems:

    bundle
    
If you have Rocket Job checked out locally, you can point to that installation
instead of the current gem by editing Gemfile and uncommenting the following line:

~~~ruby
# For testing with a local copy of the gem:
gem 'rocketjob', path: '../../rocketjob'
~~~

Optionally pre-load the database with jobs in the various states to assist with development:

    bin/rake db:seed
    
Run the above db:seed operation several times to create additional test data.

Start a Rails server:

    bin/rails s

Any changes to the views and other code should take immediate effect upon page refresh.
   
To run a console to manually create jobs, etc.:

    bin/rails c
    
Start a Rocket Job server running 10 workers:

    bin/rocketjob

Note: Running the Rocket Job server above will complete any running jobs, and process
 the queued jobs. Run db:seed above again after stopping the rocketjob server if needed.
 
Note: This dummy Rails installation works with Rails 6.0. A new dummy app
 will have to be created to support Rails 5.2 

For testing purposes the following Jobs are supplied with the rjmc dummy Rails app:
* AllTypesJob
    * Ideal for DirmonEntry Testing.
* CSVJob
    * For testing batch jobs.
* KaboomBatchJob
    * For testing batch jobs.
    * Creates test data with intentional errors and exceptions.
    