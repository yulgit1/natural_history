require 'rubygems'
require 'rsolr'
require 'rexml/document'
require 'marc'
require 'active_support/core_ext/integer/inflections'
require 'roo'

include REXML

#note - will require clean up

namespace :index do
  desc "Add missing artists to texts"
  task add_artists_to_texts: :environment do

    puts "start: #{Time.now}"
    SOLR_CONFIG = Rails.application.config_for(:blacklight) #good to know
    #ssh -i "ycba-test.pem" -L 8983:localhost:8983 10.5.96.214 -l ec2-user
    #IMPORTANT!! before running this script copy existing index open which the remaining will be updated:
      #cd /opt/blacklight-jetty/solr/bartram7
      #cp -rp data /opt/blacklight-jetty/solr/bartram8
    orig_solr_url = "http://localhost:8983/solr/bartram7"
    target_solr_url = "http://localhost:8983/solr/bartram8"
    start=0
    stop=false
    page=100 # for real
    #page=5 #temp for test
    orig_solr = RSolr.connect :url => orig_solr_url #make sure tunnelling prod!
    target_solr = RSolr.connect :url => target_solr_url

    #put authors for scans into hash
    scan_artist = Hash.new
    start=0
    stop=false
    page=100 # for real
    while stop!=true
      # send a request to /select
      response = orig_solr.post 'select', :params => {
          :fq=>'format:"images"',
          :fl=>'id,scan_author_sm',
          :sort=>'id asc',
          :start=>start,
          :rows=>page
      }
      documents = Array.new

      puts "img cnt: #{response['response']['docs'].length}"
      stop = true if response['response']['docs'].length == 0

      response["response"]["docs"].each {|doc|
        scan_artist[doc["id"].to_s] = doc["scan_author_sm"]
      }
      start +=page
      sleep(1)
    end
    puts "SCAN_ARTIST SIZE: #{scan_artist.size()}"
    #puts "SCAN_ARTIST: #{scan_artist}"
    #exit #for testing

    #copy one core to another and correct location_s
    start=0
    stop=false
    page=100 # for real
    while stop!=true
      # send a request to /select
      response = orig_solr.post 'select', :params => {
          :fq=>'format:"texts" && has_scan_s:"scan" && -scan_author_sm:[* TO *]',
          :fl=>'*',
          :sort=>'id asc',
          :start=>start,
          :rows=>page
      }
      documents = Array.new

      stop = true if response['response']['docs'].length == 0
      #stop = true if start > 99 #for testing

      response["response"]["docs"].each{|doc|

        docClone=doc.clone

        docClone["scan_author_sm"] = [] if docClone["scan_author_sm"].nil?
        docClone["scan_sm"].each {|scan|
          unless docClone["scan_author_sm"].include? scan_artist[scan][0]
            puts "#{docClone["id"]} #{scan_artist[scan]}"
            docClone["scan_author_sm"] = scan_artist[scan]
          end
        }
        docClone['timestamp'] = Time.now
        documents.push(docClone)

      }
      #exit #for testing
      #sleep(10000) #for testing
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

end

