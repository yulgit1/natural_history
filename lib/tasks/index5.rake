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
  task copy_facets_fix_type: :environment do

    puts "start: #{Time.now}"
    SOLR_CONFIG = Rails.application.config_for(:blacklight) #good to know
    #ssh -i "ycba-test.pem" -L 8983:localhost:8983 10.5.96.214 -l ec2-user
    #orig_solr_url = "http://10.5.96.214:8983/solr/bartram4"
    #target_solr_url = "http://10.5.96.214:8983/solr/bartram5"
    orig_solr_url = "http://localhost:8983/solr/bartram5"
    target_solr_url = "http://localhost:8983/solr/bartram6"

    start=0
    stop=false
    page=100 # for real
    #page=5 #temp for test
    orig_solr = RSolr.connect :url => orig_solr_url #make sure tunnelling prod!
    target_solr = RSolr.connect :url => target_solr_url

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

      response["response"]["docs"].each{|doc|

        docClone=doc.clone

        docClone["format"] = "texts" if doc["format"] == "object"
        docClone["object_type_s"] = "texts" if doc["object_type_s"] == "object"
        docClone["format"] = "images" if doc["format"] == "scan"
        docClone["object_type_s"] = "images" if doc["object_type_s"] == "scan"
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

