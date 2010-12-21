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

require 'uri'

class URI::Generic
	def absolute_path?
		path.match('^/')
	end
	
	def relative_path?
		!absolute_path?
	end
	
	# Behavior in 1.8.7 seems to be broken...?
	def merge0(oth)
		case oth
		when Generic
		when String
			oth = URI.parse(oth)
		else
			raise ArgumentError, "bad argument(expected URI object or URI string)"
		end
		
		if oth.absolute?
			return oth, oth
		else
			return self.dup, oth
		end
	end
end

# puts URI.parse("/bob/dole") + URI.parse("http://www.lucidsystems.org")
