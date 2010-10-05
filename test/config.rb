require 'rubygems'
require 'test/unit'
require 'active_record'

TEST_ROOT       = File.expand_path(File.dirname(__FILE__))
FIXTURES_ROOT   = TEST_ROOT + "/fixtures"
SCHEMA_ROOT     = TEST_ROOT + "/schema"

require 'connection'
