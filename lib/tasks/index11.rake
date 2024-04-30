namespace :index do
  #torun: rake index:split_notebook_entries
  desc "add locations to notebook entries"
  task add_locations_to_notebook_entries: :environment do

    puts "start: #{Time.now}"

    #set tunneling
    #ssh -i "ycba-test.pem" -L 8983:localhost:8983 10.5.96.214 -l ec2-user

    #or open security group in amazon and connect directly
    #target_solr_url = "http://10.5.96.214:8983/solr/bartram5"

    target_solr_url = "http://localhost:8983/solr/bartram9"
    @target_solr = RSolr.connect :url => target_solr_url

    excel_filename = Rails.root.join("lib","assets","allison_knowing_nature_locations.xlsx").to_s
    xlsx = Roo::Excelx.new(excel_filename)

    rowcount = 0
    documents = Array.new
    xlsx.each_row_streaming(pad_cells: true) do |row|
      rowcount += 1
      #next if rowcount == 1
      #break if rowcount > 2
      #puts row.inspect

      timestamp = Time.now
      id = filter_cells(row[0])
      location = filter_cells(row[1])

      puts "-------------"
      puts "timestamp: #{timestamp}"
      puts "id: #{id}"
      puts "location: #{location}"
      if location == ""
        puts "EXCEPTION: location missing for id: #{id}"
        next
      end

      doc = get_solr_doc_by_id(id)
      if doc.nil?
        puts "EXCEPTION2: + no doc found for #{id}"
        next
      end
      doc["locations_sm"] = [location]
      #pp doc

      @target_solr.add [doc]
      @target_solr.commit


    end
    @target_solr.optimize
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

