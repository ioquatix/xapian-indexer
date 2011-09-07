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

require 'nokogiri'

module Xapian
	module Indexer
		module Extractors
			# Represents a resource that will be indexed
			class HTML
				NBSP = Nokogiri::HTML("&nbsp;").text
				WHITESPACE = /(\s|#{NBSP})+/
				
				def initialize(options = {})
					@options = options
					
					@logger = options[:logger] || Logger.new($stderr)
				end
			
				def call(resource, status, headers, data)
					html = Nokogiri::HTML.parse(data)
					result = {}

					# Extract description
					meta_description = html.css("meta[name='description']").first
				
					if meta_description
						result[:description] = meta_description['content']
					else
						# Use the first paragraph as a description
						first_paragraph = html.search("p").first
					
						if first_paragraph
							result[:description] = first_paragraph.inner_text.gsub(WHITESPACE, " ")
						end
					end
				
					base_tag = html.at('html/head/base')
					if base_tag
						base = URI.parse(base_tag['href'])
					else
						base = URI.parse(resource.name)
					end
					
					links = []
				
					html.css('a').each do |link| 
						href = (link['href'] || "").to_s.gsub(/ /, '%20')
					
						# No scheme but starts with a '/'
						#begin
							links << (base + href)
						#rescue
						#	$stderr.puts "Could not add link #{href}: #{$!}"
						#end
					end
				
					# Remove any fragment at the end of the URI.
					links.each{|link| link.fragment = nil}
				
					# Convert to strings and uniq.
					result[:links] = links.map{|link| link.to_s}.uniq
					
					#$stderr.puts "Extracted links = #{result[:links].inspect}"
					
					# Extract title
					title_tag = html.at('html/head/title')
					h1_tag = html.search('h1').first
					if title_tag
						result[:title] = title_tag.inner_text.gsub(WHITESPACE, " ")
					elsif h1_tag
						result[:title] = h1_tag.inner_text.gsub(WHITESPACE, " ")
					end
				
					# Extract keywords
					meta_keywords = html.css("meta[name='keyword']").first
					if meta_keywords
						result[:keywords] = meta_keywords['content'].gsub(WHITESPACE, " ")
					end
					
					# Remove junk elements from the html
					html.search("script").remove
					html.search("link").remove
					html.search("meta").remove
					html.search("style").remove
					html.search("form").remove
					html.css('.noindex').remove
					
					body = html.at('html/body')
					
					if body
						# We also convert NBSP characters to inner space.
						result[:content] = body.inner_text.gsub(WHITESPACE, " ")
					end
				
					return result
				end
			end
		end
	end
end

