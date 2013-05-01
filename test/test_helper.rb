ENV['DEBUG'] = 'true'

require 'rubygems'
require 'bundler/setup'

require 'pathname'

JRUBY = defined?(JRUBY_VERSION)

if ENV['JSON_LIBRARY']
	puts "Using '#{ENV['JSON_LIBRARY']}' JSON library"
	require ENV['JSON_LIBRARY']
else
	require 'json'
end

require_relative '../lib/dotted_hash'

if Module.const_defined?(:RSpec)
	RSpec.configure do |config|
		config.expect_with :rspec do |c|
			c.syntax = :expect
		end
	end
end


