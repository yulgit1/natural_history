require 'rubygems'
require 'rsolr'
require 'rexml/document'
require 'marc'
require 'active_support/core_ext/integer/inflections'
require 'roo'

include REXML

namespace :index do
  desc "link scan to object"
  task link_scans: :environment do

    puts "start: #{Time.now}"

    #set tunneling
    #ssh -i "ycba-test.pem" -L 8983:localhost:8983 10.5.96.214 -l ec2-user

    #or open security group in amazon and connect directly
    #target_solr_url = "http://10.5.96.214:8983/solr/bartram5"

    target_solr_url = "http://localhost:8983/solr/bartram5"
    target_solr = RSolr.connect :url => target_solr_url

    excel_filename = Rails.root.join("lib","assets","fleming-feb21_2023.xlsx").to_s
    xlsx = Roo::Excelx.new(excel_filename)
#    xlsx = xlsx.sheet("questionable") #for sheet
    h = Hash.new
    xlsx.each_row_streaming(pad_cells: true) do |row|
      scan = filter_cells(row[0])
      object = filter_cells(row[1])
      a = Array.new
      if h[object]
        a = h[object]
      end
      a.push(scan)
      h[object] = a
    end
#    h.delete_if { |k, v| k.empty? } #don't process empty k/v
    puts h.inspect
    puts h.size
    puts "-----"
    rowcount = 0
    documents = Array.new
    xlsx.each_row_streaming(pad_cells: true) do |row|
      rowcount += 1
      #next if rowcount == 1
      #break if rowcount > 3
      #puts row.inspect

      #use filter_cells method to remove highlighting, which is indicated by class Roo::Excelx::Cell::Empty
      scan = filter_cells(row[0])
      object = filter_cells(row[1])

      puts "-----"
      puts "scan:#{scan}"
      puts "object:#{object}"
#      next if scan == "" #don't process empty k/v

      resp = target_solr.get 'select', :params => {:fq => "id:\"#{object}\"",:fl => '*'}

      resp["response"]["docs"].each { |doc|
        doc["has_scan_s"] = "scan"
        doc["timestamp"] = Time.now
        doc["scan_sm"] = h[object]
        puts "solrdoc:#{doc.inspect}"
        documents.push(doc)
      }
    end
    #puts documents
    target_solr.add documents
    target_solr.commit
    target_solr.optimize
    puts "end: #{Time.now}"
  end

  def filter_cells c
    return "" if c.class.to_s == "Roo::Excelx::Cell::Empty"
    c.to_s
  end

end