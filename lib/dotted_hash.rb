# Taken from Tire::Results::Item
# but modified
require_relative "dotted_hash/version"
require 'active_model'
require 'active_support/core_ext/string/inflections'
require 'active_support/json'

class DottedHash
	extend  ActiveModel::Naming
	include ActiveModel::Conversion
	#include ActiveModel::Model

	## Basic security

	# Maximum depth of whole tree, not keys (keys depth+1)
	# Counted from 0
	# Not fully bulletproof, depth may be set to wrong number if careless
	MAX_DEPTH = 10

	# Maximum count of attributes
	# Use hash like this to specify each level
	# MAX_ATTRS = {1 => 20, 2 => 5, default: 10}
	MAX_ATTRS = 10

	# Maximum size of document, counted from JSON result of document
	# It is not bulletproof, but if using simple structures, it is enough
	# Other structures may have much bigger representation in memory than in JSON
	MAX_SIZE = 16384

	# Create new instance, recursively converting all Hashes to Item
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

	def respond_to?(method_name, include_private = false)
		# answer to any write method
		if method_name.to_s[-1] == '='
			true
		else
			@attributes.has_key?(method_name.to_sym) || super
		end
	end

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

	def [](key)
		@attributes[key.to_sym]
	end

	def id
		@attributes[:_id] || @attributes[:id]
	end

	def type
		@attributes[:_type] || @attributes[:type]
	end

	def persisted?
		!!id
	end

	def errors
		ActiveModel::Errors.new(self)
	end

	def valid?
		true
	end

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

	def as_json(options=nil)
		hash = to_hash
		hash.respond_to?(:with_indifferent_access) ? hash.with_indifferent_access.as_json(options) : hash.as_json(options)
	end

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
