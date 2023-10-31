require 'rubygems'
require 'rsolr'
require 'rexml/document'
require 'marc'
require 'active_support/core_ext/integer/inflections'
require 'roo'

include REXML

#note - will require clean up

namespace :index do
  desc "Copy index original index and add facets"
  task add_locations_to_text: :environment do

    puts "start: #{Time.now}"
    SOLR_CONFIG = Rails.application.config_for(:blacklight) #good to know
    #ssh -i "ycba-test.pem" -L 8983:localhost:8983 10.5.96.214 -l ec2-user
    #orig_solr_url = "http://10.5.96.214:8983/solr/bartram4"
    #target_solr_url = "http://10.5.96.214:8983/solr/bartram5"
    orig_solr_url = "http://localhost:8983/solr/bartram6"
    target_solr_url = "http://localhost:8983/solr/bartram7"
    start=0
    stop=false
    page=100 # for real
    #page=5 #temp for test
    orig_solr = RSolr.connect :url => orig_solr_url #make sure tunnelling prod!
    target_solr = RSolr.connect :url => target_solr_url

    #put locations for scans into hash
    scan_location = Hash.new
    start=0
    stop=false
    page=100 # for real
    while stop!=true
      # send a request to /select
      response = orig_solr.post 'select', :params => {
          :fq=>'format:"images" && location_s:[0 TO *]',
          :fl=>'id,location_s',
          :sort=>'id asc',
          :start=>start,
          :rows=>page
      }
      documents = Array.new

      stop = true if response['response']['docs'].length == 0

      response["response"]["docs"].each {|doc|
      scan_location[doc["id"].to_s] = doc["location_s"]
      }
      start +=page
      sleep(1)
    end
    #puts "SCAN_LOCATION SIZE: #{scan_location.size()}" #844
    #puts "SCAN_LOCATION: #{scan_location}"
    #test_one = "scan-0873"
    #puts "One: #{scan_location[test_one]}"

    #copy one core to another and correct location_s
    start=0
    stop=false
    page=100 # for real
    while stop!=true
      # send a request to /select
      response = orig_solr.post 'select', :params => {
          #:fq=>'format:"scan"',
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
        if doc["location_s"]
          docClone["locations_sm"] = [] if docClone["locations_sm"].nil?
          docClone["locations_sm"] << doc["location_s"] unless doc["location_s"] == "Yale Center for British Art"
        end

        if doc["scan_sm"]
          doc["scan_sm"].each { |s|
            if scan_location[s]
              #puts "add to #{doc["id"]} #{s} = #{scan_location[s]}"
              docClone["locations_sm"] = [] if docClone["locations_sm"].nil?
              docClone["locations_sm"] << scan_location[s] unless docClone["locations_sm"].include? scan_location[s]
            else
              puts "no scan location for #{s}"
            end
          }
        else
          #puts "no change to #{doc["id"]}"
        end

        if doc["author_display"]
          docClone["scan_author_sm"] = [] if docClone["scan_author_sm"].nil?
          docClone["scan_author_sm"] << doc["author_display"]
        end

        #test
        puts "With location #{docClone["id"]}  #{docClone["locations_sm"]}" if docClone["locations_sm"] && docClone["locations_sm"].size() > 0

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

  def parsenames s
    #s.split(",").collect(&:strip).reject {|v| v.empty?}.collect { |v| v.split(")").collect{|x| x.split("(")[0]}.join}.collect(&:strip).collect { |x| x.gsub(/ +/, " ")}
    if s[0].to_i > 0
      s2 = s.split(/(\d+\.)/).reject.each_with_index { |s,i| i.odd? }.collect(&:strip).collect { |v| v.chomp(",")}.reject {|v| v.empty?}.collect { |v| v.split(")").collect{|x| x.split("(")[0]}.join}.collect(&:strip).collect { |x| x.gsub(/ +/, " ")}
    elsif s[0].to_i == 0
      s.split(")").collect{|x| x.split("(")[0]}.join.split(",").collect(&:strip).reject {|v| v.empty?}.collect { |x| x.gsub(/ +/, " ")}
    end
  end
end

