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

require 'xapian'
require 'set'

module Xapian
	module Indexer
		# Represents a process which consumes resources into the database
		# and follows links to related resources
		class Spider
			# database = Xapian::Database.new(ARGV[0])
			def initialize(database, generator, controller, options = {})
				@database = database
				@generator = generator
				@controller = controller
				
				@links = []
				@touched = Set.new
				
				@logger = options[:logger] || Logger.new($stdout)
			end
			
			attr :resources
			
			def add(root)
				case root
				when String
					@links << root
				when Array
					@links += root
				else
					@logger.error "Could not add roots #{root.inspect}!"
				end
			end
			
			class Fetch
				def initialize(database, controller, link)
					@database = database
					@controller = controller
					
					@document = false
					@current_resource = controller.create(link)
					@archived_resource = false
				end
				
				attr :database
				attr :controller
				attr :current_resource
				
				def document
					if @document === false
						postlist = @database.postlist(@current_resource.name_digest)

						if postlist.size > 0
							@document = @database.document(postlist[0].docid)
						else
							@document = nil
						end
					end
					
					return @document
				end
				
				def archived_resource
					if @archived_resource === false
						if document
							@archived_resource = @controller.recreate(document.data)
						end
					end
					
					return @archived_resource
				end
				
				def links
					#$stderr.puts "current_resource.links = #{@current_resource.links.inspect}" if @current_resource
					#$stderr.puts "archived_resource.links = #{archived_resource.links.inspect}" if archived_resource
					
					if @current_resource.fetched?
						@current_resource.links
					elsif archived_resource
						archived_resource.links
					end
				end
			end
			
			def process(options = {}, &block)
				count = 0
				depth = 0
				
				until @links.empty?
					new_links = []
					
					@links.each do |link|
						# Mark and sweep - don't review the same resource twice!
						next if @touched.include?(link)
						@touched << link
						
						# Create a new fetch from the database...
						fetch = Fetch.new(@database, @controller, link)
						resource = fetch.current_resource
						
						# Does it already exist in the current database (and fresh?)
						unless fetch.archived_resource && fetch.archived_resource.fresh?
							# Fetch the resource and add it to the index
							begin
								@logger.info "Indexing #{resource.name}..."
								resource.fetch!
							rescue
								@logger.error "Could not fetch resource #{resource.name}: #{$!}!"
								$!.backtrace.each{|line| @logger.error(line)}
							end
							
							# Did we fetch a resource and was it indexable?
							if resource.fetched?
								if resource.content?
									doc = Xapian::Document.new
									doc.data = @controller.save(resource)
									doc.add_term(resource.name_digest)
						
									@generator.document = doc
									@generator.index_text(resource.content)
									@database.replace_document(resource.name_digest, doc)
								else
									@logger.warn "Resource was not indexable #{resource.name}!"
								end
							else
								@logger.warn "Could not fetch resource #{resource.name}!"
							end
						else
							@logger.info "Still fresh #{resource.name}..."
						end
						
						new_links += (fetch.links || []).map(&block).compact
						
						count += 1
						
						if options[:count] && count > options[:count]
							# If we have to leave before finishing this breadth...
							@links += new_links
							return count
						end
					end
					
					@links = new_links
					
					depth += 1
					
					return count if options[:depth] && depth > options[:depth]
				end
			end
			
			def remove_old!
				postlist = @database.postlist("")
				
				postlist.each do |post|
					document = @database.document(post.docid)
					resource = @controller.recreate(document.data)
					
					unless resource.fresh?
						@logger.info "Removing expired index for #{resource.name}."
						@database.delete_document(post.docid)
					end
				end
			end
		end
		
	end
end
