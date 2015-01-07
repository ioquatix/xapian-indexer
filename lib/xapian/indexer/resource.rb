# Copyright (c) 2010 Samuel Williams. Released under the GNU GPLv3.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
