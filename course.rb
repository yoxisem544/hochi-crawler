require 'json'

class Course

	attr_accessor :book_category, :detailed_book_category, :book_name, :book_number, :price, :selling_price, :isbn, :author_translator, :edition
	def initialize(h)
		@attributes = [:book_category, :detailed_book_category, :book_name, :book_number, :price, :selling_price, :isbn, :author_translator, :edition]
    h.each {|k, v| send("#{k}=",v)}
	end

	def to_hash
		@data = Hash[ @attributes.map {|d| [d.to_s, self.instance_variable_get('@'+d.to_s)]} ]
	end

	def to_json
		JSON.pretty_generate @data
	end
end
