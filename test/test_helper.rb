ENV['RAILS_ENV'] ||= 'test'
require_relative '../rjmc/config/environment'

require 'yaml'
require 'minitest/autorun'
require 'minitest/stub_any_instance'
require 'awesome_print'
