require 'rubygems'
require 'rsolr'
require 'rexml/document'
require 'marc'
require 'active_support/core_ext/integer/inflections'
require 'roo'

include REXML

#note - will require clean up

namespace :index do
  desc "Solr to csv"
  task solr_to_csv: :environment do

    #puts "start: #{Time.now}"
    SOLR_CONFIG = Rails.application.config_for(:blacklight) #good to know
    #ssh -i "ycba-test.pem" -L 8983:localhost:8983 10.5.96.214 -l ec2-user

    target_solr_url = "http://localhost:8983/solr/bartram7"

    start=0
    stop=false
    page=100 # for real
    #page=5 #temp for test
    target_solr = RSolr.connect :url => target_solr_url

    while stop!=true
      # send a request to /select
      response = target_solr.post 'select', :params => {
          #:fq=>'-scan_author_sm:[* TO *]',
          #:fq=>'-locations_sm:[* TO *] && format:"images"',
          :fq=>'-locations_sm:[* TO *] && format:"texts"',
          :fl=>'id,has_scan_s',
          :sort=>'id asc',
          :start=>start,
          :rows=>page
      }
      documents = Array.new

      stop = true if response['response']['docs'].length == 0

      response["response"]["docs"].each{|doc|

        #puts "#{doc["id"]},#{doc["has_scan_s"]}"
        puts doc["id"]

      }

      start +=page
    end
    #puts "end: #{Time.now}"
  end

end

