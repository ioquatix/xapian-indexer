# Copyright, 2015, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'digest/md5'
require 'yaml'

module Xapian
	module Indexer
		
		class Controller
			def initialize(options = {})
				@extractors = {}
				@loaders = []
				
				@logger = options[:logger] || Logger.new($stderr)
			end
			
			attr :loaders
			attr :extractors
			
			def create(name)
				Resource.new(name, self)
			end
			
			def load(resource, &block)
				@loaders.each do |loader|
					loader.call(resource.name) do |status, header, load_body|
						if status >= 200 && status < 300
							# Process the page content
							mime_type = header['content-type'].split(";").first
							extractor = @extractors[mime_type]

							if extractor
								body = load_body.call
								metadata = extractor.call(resource, status, header, body)

								# Load the data into the resource
								yield status, header, body, metadata

								return true
							else
								@logger.warn "Ignoring resource #{resource.name} because content-type #{mime_type} is not supported."
								return false
							end
						elsif status >= 300 && status < 400
							# Process the redirect
							location = URI.parse(resource.name) + header['location']
							
							metadata = {
								:links => [location.to_s]
							}
							
							# This resource is not indexable, using nil for body
							yield status, header, nil, metadata
						end
					end
				end
				
				return false
			end
			
			def save(resource)
				YAML::dump(resource.to_hash)
			end
			
			def recreate(data)
				values = YAML::load(data)
				
				Resource.new(values[:name], self, values)
			end
		end
		
		# Represents a resource that will be indexed
		class Resource
			def initialize(name, controller, values = {})
				@name = name
				@controller = controller
				
				@fetched_on = values[:fetched_on]
				@status = values[:status]
				@header = values[:header]
				@body = values[:body]
				@metadata = values[:metadata]
			end
			
			attr :name
			attr :status
			attr :header
			attr :body
			attr :metadata
			
			def to_hash
				{
					:fetched_on => @fetched_on,
					:name => @name,
					:status => @status,
					:header => @header,
					:body => @body,
					:metadata => @metadata
				}
			end
			
			# The data that will be indexed
			def content
				[@metadata[:content] || @body, @metadata[:title], @metadata[:description], @metadata[:keywords]].compact.join(" ")
			end
			
			def links
				@metadata[:links] if @metadata
			end
			
			def fresh?(at = Time.now)
				cache_control = @header['cache-control'] || ""
				fetched_age = @header['age'] || ""
				max_age = 3600
				
				if cache_control.match(/max-age=([0-9]+)/)
					max_age = $1.to_i
					
					if fetched_age.match(/([0-9]+)/)
						max_age -= $1.to_i
					end
				end
				
				age = at - @fetched_on
				
				# If the page is younger than the max_age the page can be considered fresh.
				return age < max_age
			end
			
			def fetch!
				@controller.load(self) do |status, header, body, metadata|
					@fetched_on = Time.now
					@status = status
					@header = header
					@body = body
					@metadata = metadata
				end
			end
			
			def fetched?
				@fetched_on != nil
			end
			
			def content?
				@body != nil
			end
			
			def name_digest
				"Q" + Digest::MD5.hexdigest(@name)
			end
		end
		
	end
end
