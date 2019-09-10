require 'rsolr'

#Blacklight.blacklight_yml[Rails.env]["url"] get from rails c or config file
url = "<>"
if ARGV[0] == "add"
  solr = RSolr.connect :url => url
  solr.add :id=>"scan-9999", :test_field1_s=> "qwer", :test_field2_s => "asdf", :test_field3_t => "cxvb"
  solr.commit
end

if ARGV[0] == "delete"
  solr = RSolr.connect :url => url
  solr.delete_by_id "scan-9999"
  solr.commit
end

if ARGV[0] == "checkconnection"
  puts "solr connection: #{url}"
end

puts "script finished"


