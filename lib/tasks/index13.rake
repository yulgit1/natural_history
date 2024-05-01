
namespace :index do
  #torun: rake index:split_notebook_entries
  desc "fix current sci vern names"
  task fix_current_sci_vern_names: :environment do

    puts "start: #{Time.now}"

    #set tunneling
    #ssh -i "ycba-test.pem" -L 8983:localhost:8983 10.5.96.214 -l ec2-user

    #or open security group in amazon and connect directly
    #target_solr_url = "http://10.5.96.214:8983/solr/bartram5"

    target_solr_url = "http://localhost:8983/solr/bartram9"
    @target_solr = RSolr.connect :url => target_solr_url

    excel_filename = Rails.root.join("lib","assets","scan-0210 and scan-0215.xlsx").to_s
    xlsx = Roo::Excelx.new(excel_filename)

    rowcount = 0

    xlsx.each_row_streaming(pad_cells: true) do |row|
      rowcount += 1
      #next if rowcount == 1
      #break if rowcount > 2
      #puts row.inspect

      timestamp = Time.now
      id = row[0]
      csn_t_orig = row[1]
      csn_t_new = row[2]
      csn_sm_orig = row[3]
      csn_sm_new = row[4]
      cvn_sm_orig = row[5]
      cvn_sm_new = row[6]
      cvn_t_orig = row[7]
      cvn_t_new = row[8]

      doc = get_solr_doc_by_id(id)

      puts "-------------"
      puts "timestamp: #{timestamp}"
      puts "id: #{id}"
      puts "current sci attrib orig: #{csn_t_orig}"
      puts "current sci attrib new: #{csn_t_new}"
      puts "current sci facet orig: #{csn_sm_orig}"
      puts "current sci facet new: #{csn_sm_new}"
      puts "current vern facet orig: #{cvn_sm_orig}"
      puts "current vern facet new: #{cvn_sm_new}"
      puts "current vern attrib orig: #{cvn_t_orig}"
      puts "current vern attrib new: #{cvn_t_new}"

      #had to add to_s to not get excel cell metadata
      doc["csn_t"] = [csn_t_new.to_s]
      doc["csn_sm"] = [csn_sm_new.to_s]
      doc["cvn_sm"] = [cvn_sm_new.to_s]
      doc["cvn_t"] = [cvn_t_new.to_s]

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