require 'rubygems'
require 'rsolr'
require 'rexml/document'
require 'marc'
require 'active_support/core_ext/integer/inflections'
require 'roo'

include REXML

namespace :index do
  desc "Copy index original index and augment"
  task copy: :environment do

    puts "start: #{Time.now}"
    SOLR_CONFIG = Rails.application.config_for(:blacklight)
    orig_solr_url = "http://10.5.96.214:8983/solr/bertram2"
    target_solr_url = "http://10.5.96.214:8983/solr/bartram3"
    start=0
    stop=false
    page=100
    orig_solr = RSolr.connect :url => orig_solr_url #make sure tunnelling prod!
    target_solr = RSolr.connect :url => target_solr_url

    excel_filename = Rails.root.join("lib","assets","tang-jun5_2019.xlsx").to_s
    excel_hash = load_excel(excel_filename)

    while stop!=true
      # send a request to /select
      response = orig_solr.post 'select', :params => {
          #:fq=>'object_type_s:"scan"',
          :fl=>'*',
          :sort=>'id asc',
          :start=>start,
          :rows=>page
      }
      documents = Array.new

      stop = true if response['response']['docs'].length == 0

      response["response"]["docs"].each{|doc|

        docClone=doc.clone

        if doc["object_type_s"] == "scan"
          id = doc["id"].to_s
          excel_row = excel_hash[id]

          docClone["csn_t"] = excel_row[0]
          docClone["cvn_t"] = excel_row[1]
          docClone["hsn_t"] = excel_row[2]
          docClone["hvn_t"] = excel_row[3]
          docClone["notes_t"] = excel_row[4]
          docClone["sources_t"] = excel_row[5]

          #docClone.each do |key, array|
          #end
        end

        docClone['timestamp'] = Time.now

        documents.push(docClone)

      }
      puts "page:"+start.to_s
      puts "len:" + documents.length.to_s
      target_solr.add documents
      target_solr.commit
      start +=page
      sleep(1)  #be kind to others :)
      #stop = true #temp for test
    end
    target_solr.optimize
    puts "end: #{Time.now}"
  end

  desc 'Clear the index.  Deletes all documents in the index'
  task clear: :environment do
    target_solr_url = "http://10.5.96.214:8983/solr/bartram3"
    solr = RSolr.connect :url => target_solr_url
    solr.delete_by_query "id:*"
    solr.commit
    solr.optimize
  end

  desc 'Replace_manifest. GSUB replacement of iiif_manifest_s field'
  task replace_manifest: :environment do

    puts "start: #{Time.now}"
    SOLR_CONFIG = Rails.application.config_for(:blacklight)
    orig_solr_url = "http://10.5.96.214:8983/solr/bartram3"
    target_solr_url = "http://10.5.96.214:8983/solr/bartram3"
    orig_host = "https://s3.amazonaws.com/bertrammanifests"
    new_host = "https://s3.amazonaws.com/bartrammanifests"
    start=0
    stop=false
    page=100
    orig_solr = RSolr.connect :url => orig_solr_url #make sure tunnelling prod!
    target_solr = RSolr.connect :url => target_solr_url

    while stop!=true
      # send a request to /select
      response = orig_solr.post 'select', :params => {
          :fq=>'object_type_s:"scan"',
          :fl=>'*',
          :sort=>'id asc',
          :start=>start,
          #:rows=>1 #to test
          :rows=>page
      }
      documents = Array.new

      stop = true if response['response']['docs'].length == 0

      response["response"]["docs"].each{|doc|

        puts "ID#{doc["id"]}"
        docClone=doc.clone
        #"iiif_manifest_s": "https://s3.amazonaws.com/bertrammanifests/scan-0001.json",
        orig_manifest = doc["iiif_manifest_s"]
        new_manifest = orig_manifest.gsub(orig_host,new_host)
        docClone["iiif_manifest_s"] = new_manifest
        docClone['timestamp'] = Time.now

        documents.push(docClone)

      }
      puts "page:"+start.to_s
      puts "len:" + documents.length.to_s
      target_solr.add documents
      target_solr.commit
      start +=page
      sleep(1)  #be kind to others :)
      #stop = true #temp for test
    end
    target_solr.optimize
    puts "end: #{Time.now}"
  end

  def load_excel(excel_filename)
    #puts "Filename:"+excel_filename
    xlsx = Roo::Spreadsheet.open(excel_filename)
    workbook = xlsx.sheet(0)

    headers = Hash.new
    workbook.row(1).each_with_index {|header,i|
      headers[header] = i
    }
    puts "Headers from excel:"
    puts headers.inspect

    loaded_hash = Hash.new
    ((workbook.first_row + 1)..workbook.last_row).each do |row|
      id = workbook.row(row)[0]
      a = Array.new
      a.push(workbook.row(row)[1])
      a.push(workbook.row(row)[2])
      a.push(workbook.row(row)[3])
      a.push(workbook.row(row)[4])
      a.push(workbook.row(row)[5])
      a.push(workbook.row(row)[6])
      loaded_hash[id] = a
    end
    return loaded_hash
  end
end