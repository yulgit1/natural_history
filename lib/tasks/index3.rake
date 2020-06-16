require 'rubygems'
require 'rsolr'
require 'rexml/document'
require 'marc'
require 'active_support/core_ext/integer/inflections'
require 'roo'

include REXML

namespace :index do
  desc "add new scans from spreadsheet"
  task add_new_scans: :environment do

    puts "start: #{Time.now}"
    SOLR_CONFIG = Rails.application.config_for(:blacklight) #good to know
    target_solr_url = "http://10.5.96.214:8983/solr/bartram5"
    start=0
    stop=false
    page=100
    target_solr = RSolr.connect :url => target_solr_url

    excel_filename = Rails.root.join("lib","assets","tang-may1_2020.xlsx").to_s
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