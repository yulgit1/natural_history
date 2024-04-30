require 'rubygems'
require 'rsolr'
require 'rexml/document'
require 'active_support/core_ext/integer/inflections'
require 'roo'
require 'pp'

include REXML

namespace :index do
  #torun: rake index:split_notebook_entries
  desc "split erroneous notebook entries"
  task split_notebook_entries: :environment do

    puts "start: #{Time.now}"

    #set tunneling
    #ssh -i "ycba-test.pem" -L 8983:localhost:8983 10.5.96.214 -l ec2-user

    #or open security group in amazon and connect directly
    #target_solr_url = "http://10.5.96.214:8983/solr/bartram5"

    target_solr_url = "http://localhost:8983/solr/bartram9"
    @target_solr = RSolr.connect :url => target_solr_url

    excel_filename = Rails.root.join("lib","assets","allison_notebook7.xlsx").to_s
    xlsx = Roo::Excelx.new(excel_filename)

    rowcount = 0
    documents = Array.new
    xlsx.each_row_streaming(pad_cells: true) do |row|
      rowcount += 1
      #next if rowcount == 1
      #break if rowcount > 1
      #puts row.inspect

      timestamp = Time.now
      id_orig = filter_cells(row[0])
      entry_orig = id_orig.split("_")[0][1..-1]
      book_orig = id_orig.split("_")[1][1..-1]
      object_orig = id_orig.split("_")[2][1..-1]
      label_orig = "Notebook #{book_orig}, Entry #{entry_orig}, Object #{object_orig}"
      entries_orig = filter_cells(row[1])
      location_orig = filter_cells(row[2])

      id_new = filter_cells(row[3])
      entry_new = id_new.split("_")[0][1..-1]
      book_new = id_new.split("_")[1][1..-1]
      object_new = id_new.split("_")[2][1..-1]
      label_new = "Notebook #{book_new}, Entry #{entry_new}, Object #{object_new}"
      entries_new = filter_cells(row[4])
      location_new = filter_cells(row[5])

      doc_orig = get_solr_doc_by_id(id_orig)
      doc_new = get_solr_doc_by_id(id_orig)

      puts "-------------"
      puts "timestamp: #{timestamp}"
      puts "id_orig: #{id_orig}"
      puts "entry_orig: #{entry_orig}"
      puts "book_orig: #{book_orig}"
      puts "object_orig: #{object_orig}"
      puts "label_orig: #{label_orig}"
      puts "location_orig: #{location_orig}"
      puts "entries_orig: #{entries_orig}"
      puts "---"
      puts "id_new: #{id_new}"
      puts "entry_new: #{entry_new}"
      puts "book_new: #{book_new}"
      puts "object_new: #{object_new}"
      puts "label_new: #{label_new}"
      puts "location_new: #{location_new}"
      puts "entries_new: #{entries_new}"
      #puts "doc_template"
      # pp doc
      puts "---"

      doc_orig["id"] = id_orig
      doc_orig["entry_s"] = entry_orig
      doc_orig["book_s"] = book_orig
      doc_orig["object_s"] = object_orig
      doc_orig["label_s"] = label_orig
      doc_orig["locations_sm"] = [location_orig]
      doc_orig["entries_t"] = [entries_orig]
      doc_orig["timestamp"] = timestamp

      doc_new["id"] = id_new
      doc_new["entry_s"] = entry_new
      doc_new["book_s"] = book_new
      doc_new["object_s"] = object_new
      doc_new["label_s"] = label_new
      doc_new["locations_sm"] = [location_new]
      doc_new["entries_t"] = [entries_new]
      doc_new["timestamp"] = timestamp

      puts "doc_orig:"
      pp doc_orig
      puts ""
      puts "doc_new:"
      pp doc_new

      @target_solr.add [doc_orig,doc_new]
      @target_solr.commit
      @target_solr.optimize
    end

    puts "end: #{Time.now}"
    puts "rowcount: #{rowcount}"

  end

  def get_solr_doc_by_id(id)
    response = @target_solr.post 'select', :params => {
      :q=>id,
      :fl=>'*',
      :rows=>1
    }

    #return [] if response['response']['docs'].length == 0
    doc = response["response"]["docs"][0]
    return doc
  end

  def filter_cells c
    return "" if c.class.to_s == "Roo::Excelx::Cell::Empty"
    c.to_s
  end
end
