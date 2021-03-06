# Taken from Tire::Results::Item
# but modified
require_relative "dotted_hash/version"
require 'active_model'
require 'active_support/core_ext/string/inflections'
require 'active_support/json'

# See Readme.md in gem/repository directory for usage instructions
class DottedHash
	extend  ActiveModel::Naming
	include ActiveModel::Conversion
	#include ActiveModel::Model

	## Basic security

	# Maximum depth of whole tree, not keys (keys depth+1).
	# Counted from 0.
	# Not fully bulletproof, depth may be set to wrong number if careless.
	MAX_DEPTH = 10

	# Maximum count of attributes.
	# Use hash like this to specify each level.
	# MAX_ATTRS = {1 => 20, 2 => 5, default: 10}
	MAX_ATTRS = 10

	# Maximum size of document, counted from JSON result of document.
	# It is not bulletproof, but if using simple structures, it is enough.
	# Other structures may have much bigger representation in memory than in JSON.
	MAX_SIZE = 16384

	# Create new instance, recursively converting all Hashes to DottedHash
	# and leaving everything else alone.
	#
	def initialize(args={}, level=0)
		raise ArgumentError, "Please pass a Hash-like object" unless args.respond_to?(:each_pair)
		raise RuntimeError, "Maximal depth reached" if level > MAX_DEPTH

		@depth = level
		@attributes = {}
		args.each_pair do |key, value|
			assign_value(key, value)
		end
	end
	
	# Merge with another hash
	def merge!(obj)
		if obj.respond_to? :to_h
		  hash = obj.to_h
		elsif obj.respond_to? :to_hash
		  hash = obj.to_hash
		else
		  raise('Merge works only with hashlike object')
		end
		
		hash.each do |key, value|
			assign_value(key, value)
		end
		self
	end

	def assign_value(key, value)
		max_attrs = if MAX_ATTRS.is_a?(Fixnum)
									MAX_ATTRS
								elsif MAX_ATTRS.respond_to?(:[])
									MAX_ATTRS[@depth] || MAX_ATTRS[:default]
								end

		if max_attrs
			attrs = @attributes.size + (@attributes.include?(key.to_sym) ? 0 : 1)
			raise RuntimeError, "Maximum number of attributes reached" if attrs > max_attrs
		end

		raise RuntimeError, "Maximal size of document reached" if self.to_json.size+value.to_json.size > MAX_SIZE

		if value.is_a?(Array)
			@attributes[key.to_sym] = value.map { |item| @attributes[key.to_sym] = item.is_a?(Hash) ? DottedHash.new(item.to_hash, @depth+1) : item }
		else
			@attributes[key.to_sym] = value.is_a?(Hash) ? DottedHash.new(value.to_hash, @depth+1) : value
		end
	end

	private :assign_value

	# Delegate method to a key in underlying hash, if present, otherwise return +nil+.
	#
	def method_missing(method_name, *arguments)
		if method_name.to_s[-1] == '=' && arguments.size == 1
			attribute = method_name.to_s.chop
			value = arguments.first
			assign_value(attribute, value)
		else
			@attributes[method_name.to_sym]
		end
	end

	# Always respond to write.
	# Respond to attribute or defined method.
	#
	def respond_to?(method_name, include_private = false)
		# answers to any write method
		if method_name.to_s[-1] == '='
			true
		else
			@attributes.has_key?(method_name.to_sym) || super
		end
	end

	# Recursively assigns value.
	# Also creates sub-DottedHashes if they don't exist).
	#
	def recursive_assign(key, value)
		return nil if key.blank?
		keys = key.split('.')
		if keys.size > 1
			key = keys.shift.to_sym

			if !@attributes[key]
				assign_value(key, DottedHash.new({}, @depth+1))
			end
			sub = @attributes[key]
			sub.send(:recursive_assign, keys.join('.'), value)
		elsif keys.size == 1
			assign_value(keys.shift, value)
		end
	end

	# Provides access to attribute.
	# Use when you have spaces and other non +a-z_+ characters in attribute name.
	#
	def [](key)
		@attributes[key.to_sym]
	end

	# Returns +id+ of document
	#
	def id
		@attributes[:id]
	end

	def persisted?
		!!id
	end

	# Standard ActiveModel Errors
	def errors
		ActiveModel::Errors.new(self)
	end

	# Always +true+
	def valid?
		true
	end

	# Returns key if key exists
	def to_key
		persisted? ? [id] : nil
	end

	def to_hash
		@attributes.reduce({}) do |sum, item|
			sum[ item.first ] = item.last.respond_to?(:to_hash) ? item.last.to_hash : item.last
			sum
		end
	end

	alias_method :to_h, :to_hash

	# Returns (filtered) Ruby +Hash+ with characters 
	# and objects only allowed in JSON.
	#
	def as_json(options=nil)
		hash = to_hash
		hash.respond_to?(:with_indifferent_access) ? hash.with_indifferent_access.as_json(options) : hash.as_json(options)
	end

	# JSON string of +as_json+ result
	def to_json(options=nil)
		as_json.to_json(options)
	end
	alias_method :to_indexed_json, :to_json

	# Let's pretend we're someone else in Rails
	#
	def class
		begin
			defined?(::Rails) && @attributes[:_type] ? @attributes[:_type].camelize.constantize : super
		rescue NameError
			super
		end
	end

	def inspect
		s = []; @attributes.each { |k,v| s << "#{k}: #{v.inspect}" }
		%Q|<DottedHash#{self.class.to_s == 'DottedHash' ? '' : " (#{self.class})"} #{s.join(', ')}>|
	end
end
