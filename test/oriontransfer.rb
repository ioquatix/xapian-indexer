#!/usr/bin/env ruby

require 'rubygems'

require 'uri'

require 'xapian/indexer'
require 'xapian/indexer/loaders/http'
require 'xapian/indexer/extractors/html'

$stderr.sync = true

database = Xapian::WritableDatabase.new("/tmp/xapian-oriontransfer", Xapian::DB_CREATE_OR_OPEN)
generator = Xapian::TermGenerator.new()

# Setup the controller
controller = Xapian::Indexer::Controller.new

controller.loaders << Xapian::Indexer::Loaders::HTTP.new()
controller.extractors['text/html'] = Xapian::Indexer::Extractors::HTML.new()

spider = Xapian::Indexer::Spider.new(database, generator, controller)

spider.add("http://www.oriontransfer.co.nz/welcome/index")

spider.process(:depth => 2, :count => 50) do |link|
	uri = URI.parse(link)
	
	case uri.host
	when "www.oriontransfer.co.nz"
		link
	else
		$stderr.puts "Skipping #{link}"
		nil
	end
end

# Start an enquire session.
enquire = Xapian::Enquire.new(database)

# Setup the query parser
qp = Xapian::QueryParser.new()
query = qp.parse_query("services")

enquire.query = query
matchset = enquire.mset(0, 10)

# Display the results.
puts "#{matchset.matches_estimated()} results found."
puts "Matches 1-#{matchset.size}:\n"

matchset.matches.each do |m|
	resource = YAML::load(m.document.data)
	puts "#{m.rank + 1}: #{m.percent}% docid=#{m.docid} [#{resource[:name]}]"
end
