namespace :index do
  #torun: rake index:split_notebook_entries
  desc "delete entries to cleanup after move"
  task delete_entries_to_cleanup: :environment do

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

      puts "-------------"
      puts "timestamp: #{timestamp}"
      puts "delete id_orig: #{id_orig}"

      @target_solr.delete_by_id id_orig
      @target_solr.commit
      @target_solr.optimize

    end

    puts "end: #{Time.now}"
    puts "rowcount: #{rowcount}"

  end
end
