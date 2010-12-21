#!/usr/bin/env ruby

require 'rubygems'

require 'uri'

require 'xapian/indexer'
require 'xapian/indexer/web_resource'

$stderr.sync = true

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

# Start an enquire session.
enquire = Xapian::Enquire.new(database)

# Setup the query parser
qp = Xapian::QueryParser.new()
query = qp.parse_query("Goblin Hacker")

enquire.query = query
matchset = enquire.mset(0, 10)

# Display the results.
puts "#{matchset.matches_estimated()} results found."
puts "Matches 1-#{matchset.size}:\n"

matchset.matches.each do |m|
	resource = YAML::load(m.document.data)
	puts "#{m.rank + 1}: #{m.percent}% docid=#{m.docid} [#{resource[:name]}]"
end
