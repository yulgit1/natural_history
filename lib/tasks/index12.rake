
namespace :index do
  #torun: rake index:split_notebook_entries
  desc "update (a) location"
  task update_location: :environment do

    puts "start: #{Time.now}"

    #set tunneling
    #ssh -i "ycba-test.pem" -L 8983:localhost:8983 10.5.96.214 -l ec2-user

    #or open security group in amazon and connect directly
    #target_solr_url = "http://10.5.96.214:8983/solr/bartram5"

    target_solr_url = "http://localhost:8983/solr/bartram9"
    @target_solr = RSolr.connect :url => target_solr_url

    excel_filename = Rails.root.join("lib","assets","scan-0730.xlsx").to_s
    xlsx = Roo::Excelx.new(excel_filename)

    rowcount = 0

    xlsx.each_row_streaming(pad_cells: true) do |row|
      rowcount += 1
      #next if rowcount == 1
      #break if rowcount > 2
      #puts row.inspect

      timestamp = Time.now
      id = row[0]
      location_orig = row[1]
      location_new = row[2]

      doc = get_solr_doc_by_id(id)

      puts "-------------"
      puts "timestamp: #{timestamp}"
      puts "id: #{id}"
      puts "location_orig: #{location_orig}"
      puts "location_new: #{location_new}"

      doc["locations_sm"] = [location_new.to_s]
      #doc["timestamp"] = timestamp

      pp doc

      @target_solr.add [doc]
      @target_solr.commit
      @target_solr.optimize

    end
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