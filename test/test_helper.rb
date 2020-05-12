# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require 'rubygems'
gemfile = File.expand_path('../../Gemfile', __FILE__)

ENV['BUNDLE_GEMFILE'] = gemfile
require 'bundler'
Bundler.setup

require 'rubygems'
require 'active_support'
require 'active_support/dependencies'
require 'active_record'
ActiveRecord::ActiveRecordError # work-around from https://rails.lighthouseapp.com/projects/8994/tickets/2577-when-using-activerecordassociations-outside-of-rails-a-nameerror-is-thrown
require 'minitest'
require 'minitest/autorun'
#require 'active_support/core_ext/logger'
require 'hobofields' if ENV['INCLUDE_HOBO']
require 'pry'
require "minitest/reporters"

junit_ouptut_dir = ENV["JUNIT_OUTPUT_DIR"].presence || "test/reports"

Minitest::Reporters.use!([
  Minitest::Reporters::ProgressReporter.new,
  Minitest::Reporters::JUnitReporter.new(junit_ouptut_dir)
])

require 'attr_default'

ActiveRecord::Base.time_zone_aware_attributes = true
Time.zone = 'Pacific Time (US & Canada)'

$LOAD_PATH.unshift File.expand_path("lib", File.dirname(__FILE__))


if defined?(Rails::Railtie)
  AttrDefault.initialize_railtie
  AttrDefault.initialize_active_record_extensions
end
