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

require 'net/http'
require 'xapian/indexer/version'

module Xapian
	module Indexer
		module Loaders
			class HTTP
				UserAgent = "Xapian-Spider #{Xapian::Indexer::VERSION}"
				
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

