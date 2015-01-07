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

