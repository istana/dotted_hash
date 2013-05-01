require_relative 'test_helper'
require 'test/unit'

class DottedHashTest < Test::Unit::TestCase
	# ActiveModel compatibility tests
	#
	def setup
		super
		begin; Object.send(:remove_const, :Rails); rescue; end
		@model = DottedHash.new :title => 'Test'
	end
    include ActiveModel::Lint::Tests
end 
