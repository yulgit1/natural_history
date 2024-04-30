namespace :index do
  #torun: rake index:split_notebook_entries
  desc "move entries to correct notebook"
  task move_entries_to_corrent_notebook: :environment do

    puts "start: #{Time.now}"

    #set tunneling
    #ssh -i "ycba-test.pem" -L 8983:localhost:8983 10.5.96.214 -l ec2-user

    #or open security group in amazon and connect directly
    #target_solr_url = "http://10.5.96.214:8983/solr/bartram5"

    target_solr_url = "http://localhost:8983/solr/bartram9"
    @target_solr = RSolr.connect :url => target_solr_url

    excel_filename = Rails.root.join("lib","assets","allison_missing_NB1.xlsx").to_s
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
      id_new = filter_cells(row[1])
      location = filter_cells(row[2])

      puts "-------------"
      puts "timestamp: #{timestamp}"
      puts "id_orig: #{id_orig}"
      puts "id_new: #{id_new}"
      puts "location: #{location}"

      doc_new = get_solr_doc_by_id(id_orig)
      entry_new = id_new.split("_")[0][1..-1]
      book_new = id_new.split("_")[1][1..-1]
      object_new = id_new.split("_")[2][1..-1]
      label_new = "Notebook #{book_new}, Entry #{entry_new}, Object #{object_new}"

      doc_new["id"] = id_new
      doc_new["entry_s"] = entry_new
      doc_new["book_s"] = book_new
      doc_new["object_s"] = object_new
      doc_new["label_s"] = label_new
      doc_new["locations_sm"] = [location]
      doc_new["timestamp"] = timestamp

      puts "---"
      pp doc_new

      @target_solr.add [doc_new]
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
