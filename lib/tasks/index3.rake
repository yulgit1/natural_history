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

    #set tunneling
    #ssh -i "ycba-test.pem" -L 8983:localhost:8983 10.5.96.214 -l ec2-user

    #or open security group in amazon and connect directly
    #target_solr_url = "http://10.5.96.214:8983/solr/bartram5"

    target_solr_url = "http://localhost:8983/solr/bartram5"
    target_solr = RSolr.connect :url => target_solr_url

    excel_filename = Rails.root.join("lib","assets","tang-may1_2020.xlsx").to_s
    xlsx = Roo::Excelx.new(excel_filename)

    rowcount = 0
    documents = Array.new
    xlsx.each_row_streaming(pad_cells: true) do |row|
      rowcount += 1
      next if rowcount == 1
      #break if rowcount > 2
      #puts row.inspect

      #use filter_cells method to remove highlighting, which is indicated by class Roo::Excelx::Cell::Empty
      id = filter_cells(row[0])
      subject_topic_pre_facet = filter_cells(row[1])
      location_s = filter_cells(row[2])
      title_t = filter_cells(row[3])
      title_display = filter_cells(row[4])
      author_display = filter_cells(row[5])
      author_t = filter_cells(row[6])
      csn_t = filter_cells(row[7])
      cvn_t = filter_cells(row[8])
      hsn_t = filter_cells(row[9])
      hvn_t = filter_cells(row[10])
      notes_t = filter_cells(row[11])
      subject_topic_s = filter_cells(row[12])
      part_of_s = filter_cells(row[13])
      recto_s = filter_cells(row[14])
      verso_s = filter_cells(row[15])
      photo_s = filter_cells(row[16])
      institutional_stamp_s = filter_cells(row[17])
      format = "scan"
      object_type_s = "scan"
      timestamp = Time.now

      csn_sm = parsenames(csn_t.to_s) unless csn_t.to_s.nil?
      cvn_sm = parsenames(cvn_t.to_s) unless cvn_t.to_s.nil?
      hsn_sm = parsenames(hsn_t.to_s) unless hsn_t.to_s.nil?
      hvn_sm = parsenames(hvn_t.to_s) unless hvn_t.to_s.nil?
      subject_topic_facet = parsenames(subject_topic_pre_facet.to_s) unless subject_topic_pre_facet.to_s.nil?

      puts "-----"
      puts "id:#{id}"
      puts "subject_topic_facet:#{subject_topic_facet}"
      puts "location_s:#{location_s}"
      puts "title_t:#{title_t}"
=begin
      puts "title_display:#{title_display}"
      puts "author_display:#{author_display}"
      puts "author_t:#{author_t}"
      puts "csn_t:#{csn_t}"
      puts "cvn_t:#{cvn_t}"
      puts "hsn_t:#{hsn_t}"
      puts "hvn_t:#{hvn_t}"
      puts "notes_t:#{notes_t}"
      puts "subject_topic_s:#{subject_topic_s}"
      puts "part_of_s:#{part_of_s}"
      puts "recto_s:#{recto_s}"
      puts "verso_s:#{verso_s}"
      puts "photo_s:#{photo_s}"
      puts "institutional_stamp_s:#{institutional_stamp_s}"
      puts "format:#{format}"
      puts "object_type_s:#{object_type_s}"
      puts "timestamp:#{timestamp}"

      #puts "csn_t:#{csn_t}"
      puts "csn_sm:#{csn_sm}"
      #puts "cvn_t:#{cvn_t}"
      puts "cvn_sm:#{cvn_sm}"
      #puts "hsn_t:#{hsn_t}"
      puts "hsn_sm:#{hsn_sm}"
      #puts "hvn_t:#{hvn_t}"
      puts "hvn_sm:#{hvn_sm}"
=end
      doc = Hash.new
      doc["id"] = id
      doc["subject_topic_facet"] = subject_topic_facet
      doc["location_s"] = location_s
      doc["title_t"] = title_t
      doc["title_display"] = title_display
      doc["author_display"] = author_display
      doc["author_t"] = author_t
      doc["csn_t"] = csn_t
      doc["cvn_t"] = cvn_t
      doc["hsn_t"] = hsn_t
      doc["hvn_t"] = hvn_t
      doc["csn_sm"] = csn_sm
      doc["cvn_sm"] = cvn_sm
      doc["hsn_sm"] = hsn_sm
      doc["hvn_sm"] = hvn_sm
      doc["notes_t"] = notes_t
      doc["subject_topic_s"] = subject_topic_s
      doc["part_of_s"] = part_of_s
      doc["recto_s"] = recto_s
      doc["verso_s"] = verso_s
      doc["photo_s"] = photo_s
      doc["institutional_stamp_s"] = institutional_stamp_s
      doc["format"] = format
      doc["object_type_s"] = object_type_s
      doc["timestamp"] = timestamp

      doc.reject! { |k,v| v==""}
      documents.push(doc)
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

  def parsenames s
    if s[0].to_i > 0
      s2 = s.split(/(\d+\.)/).reject.each_with_index { |s,i| i.odd? }.collect(&:strip).collect { |v| v.chomp(",")}.reject {|v| v.empty?}.collect { |v| v.split(")").collect{|x| x.split("(")[0]}.join}.collect(&:strip).collect { |x| x.gsub(/ +/, " ")}
    elsif s[0].to_i == 0
        s2 = s.split(",").collect(&:strip).reject {|v| v.empty?}.collect { |v| v.split(")").collect{|x| x.split("(")[0]}.join}.collect(&:strip).collect { |x| x.gsub(/ +/, " ")}
    end
    return s2
  end
end