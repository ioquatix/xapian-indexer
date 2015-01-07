# Xapian::Indexer

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

	gem 'xapian-indexer'

And then execute:

	$ bundle

Or install it yourself as:

	$ gem install xapian-indexer

## Usage

The following example shows how to create a spider and index some resources:

	database = Xapian::WritableDatabase.new("/tmp/xapian-oriontransfer", Xapian::DB_CREATE_OR_OPEN)
	generator = Xapian::TermGenerator.new()

	spider = Xapian::Indexer::Spider.new(database, generator)
	root = Xapian::Indexer::WebResource.new("http://www.oriontransfer.co.nz/welcome/index")

	spider.add(root)

	spider.fresh do |metadata|
		Xapian::Indexer::WebResource.fresh?(metadata)
	end

	spider.process(:depth => 2, :count => 50) do |link|
		uri = URI.parse(link)
	
		case uri.host
		when "www.oriontransfer.co.nz"
			Xapian::Indexer::WebResource.new(link)
		else
			$stderr.puts "Skipping #{link}"
			nil
		end
	end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2015, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.