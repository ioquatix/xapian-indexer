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

require 'uri'

class URI::Generic
	# This change allows you to merge relative URLs which otherwise isn't possible.
	def merge(oth)
		oth = parser.send(:convert_to_uri, oth)
		
		return oth if oth.absolute?
		
		base = self.dup
		rel = oth
		
		authority = rel.userinfo || rel.host || rel.port

		# RFC2396, Section 5.2, 2)
		if (rel.path.nil? || rel.path.empty?) && !authority && !rel.query
			base.fragment=(rel.fragment) if rel.fragment
			return base
		end

		base.query = nil
		base.fragment=(nil)

		# RFC2396, Section 5.2, 4)
		if !authority
			base.set_path(merge_path(base.path, rel.path)) if base.path && rel.path
		else
			# RFC2396, Section 5.2, 4)
			base.set_path(rel.path) if rel.path
		end

		# RFC2396, Section 5.2, 7)
		base.set_userinfo(rel.userinfo) if rel.userinfo
		base.set_host(rel.host)         if rel.host
		base.set_port(rel.port)         if rel.port
		base.query = rel.query       if rel.query
		base.fragment=(rel.fragment) if rel.fragment

		return base
	end
	
	alias + merge
end
