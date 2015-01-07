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

require 'net/http'
require 'xapian/indexer/version'

module Xapian
	module Indexer
		module Loaders
			class HTTP
				UserAgent = "Xapian-Spider #{Xapian::Indexer::VERSION::STRING}"
				
				def initialize(options = {})
					@options = options
					
					@logger = options[:logger] || Logger.new($stderr)
				end
				
				# Extract metadata from the document, including :content and :links
				def call(name, &block)
					uri = URI.parse(name)
					
					if uri.absolute?
						Net::HTTP.start(uri.host, uri.port) do |http|
							head = http.request_head(uri.path, 'User-Agent' => UserAgent)
						
							body = lambda do
								page = http.request_get(uri.path, 'User-Agent' => UserAgent)
								page.body
							end
						
							@logger.info "Loading external URI: #{name.inspect}"
						
							yield head.code.to_i, head.header, body
						end
						
						return true
					end
					
					return false
				end
			end
		end
	end
end

