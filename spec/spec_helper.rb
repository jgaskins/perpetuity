require 'bundler/setup'

adapter = ENV.fetch('PERPETUITY_ADAPTER') { 'mongodb' }
require "perpetuity/#{adapter}"

Perpetuity.data_source adapter.to_sym, 'perpetuity_gem_test'
