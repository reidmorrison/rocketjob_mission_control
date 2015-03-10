ENV["RAILS_ENV"] = "test"
require File.expand_path("../../test/dummy/config/environment.rb",  __FILE__)

require 'rails/test_help'
require 'minitest/rails'

require 'minitest/pride'

require 'mocha'

class ActiveSupport::TestCase

end
