## Installation

Install all needed gems to run the tests:

    appraisal install

The gems are installed into the global gem list.
The Gemfiles in the `gemfiles` folder are also re-generated.

## Run Tests

For all supported Rails/ActiveRecord versions:

    rake

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
    
If you have Rocket Job and/or Rocket Job Pro checked out locally, you can point to those installations
instead of the current gems by editing Gemfile and uncommenting the following 2 lines as applicable:

~~~ruby
# For testing with local copies of the gems:
gem 'rocketjob', path: '../../rocketjob'
gem 'rocketjob_pro', path: '../../rocketjob_pro'
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
 
Note: This dummy Rails installation works with Rails 3.2 and Rails 4.2. A new dummy app
 will have to be created to support Rails 5.1. 

For testing purposes the following Jobs are supplied with the rjmc dummy Rails app:
* AllTypesJob
    * Ideal for DirmonEntry Testing.
* CSVJob
    * For testing against RocketJob Pro.
* KaboomBatchJob
    * For testing against RocketJob Pro.
    * Creates test data with intentional errors and exceptions.
