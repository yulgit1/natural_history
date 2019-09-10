module ApplicationHelper

  def remove_ycba value
    if value == "Yale Center for British Art"
      value = "Yale Center for British Art (objects)"
    end
    value
  end

def render_entries options={}
    obj_id = options[:document][:id]
    solr = RSolr.connect :url => Blacklight.blacklight_yml[Rails.env]["url"]
    query = "scan_sm:\"#{obj_id}\""
    solr_response = solr.get 'select', :params => {:fq=> query, :rows => 10, :fl => "entries_t, id, label_s" }
    entries = []
    if solr_response["response"] && solr_response["response"]["docs"].size > 0
      solr_response["response"]["docs"].each_with_index { |doc, i|
        if doc["entries_t"][0]
          obj_link = "\n[#{doc["label_s"]}](#{doc["id"]})"
          entries.append(obj_link + doc["entries_t"][0])
        end
      }
    end
    markdown(entries.join)
  end

  def render_as_link options={}
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field

    links = []
    options[:value].each {  |link|
      links.append(link_to "#{link}", "#{link}", target: '_blank')
    }

    links.join('<br/>').html_safe
  end

  def render_scan_as_link options={}
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field
    solr = RSolr.connect :url => Blacklight.blacklight_yml[Rails.env]["url"]
    links = []
    options[:value].each {  |link|
      response = solr.get 'select', :params => {:fq => "id:#{link}"}
      title = link
      title = response["response"]["docs"][0]["title_display"] if response["response"]["docs"][0]["title_display"].nil? == false
      links.append(link_to "#{title}", "#{link}", target: '_blank')
    }

    links.join('<br/>').html_safe
  end


  def make_html_safe options={}
    fa = []
    options[:value].each {  |f|
      fa.append(f)
    }
    #options[:value][0].html_safe
    fa.join('<br/>').html_safe
  end

  def render_markdown options={}
    #markdown(options[:value][0])
    fa = []
    options[:value].each {  |f|
      fa.append(markdown(f))
    }
    #options[:value][0].html_safe
    fa.join('<br/>').html_safe
  end

  def markdown(text)
    options = {
        filter_html:     true,
        hard_wrap:       true,
        link_attributes: { rel: 'nofollow', target: "_blank" },
        space_after_headers: true,
        fenced_code_blocks: true
    }

    extensions = {
        autolink:           true,
        superscript:        true,
        disable_indented_code_blocks: true
    }

    renderer = Redcarpet::Render::HTML.new(options)
    markdown = Redcarpet::Markdown.new(renderer, extensions)

    markdown.render(text).html_safe
  end

  def pull_object_images
    markup = ""
    id = request.original_url.split("/").last.gsub("scan","image")
    dir = Rails.root.join("app","assets","images","scans")
    Dir.chdir(dir)
    sorted = Dir.glob("#{id}*.jpg").sort
    sorted.each do |f|
      #image-0001-00.jpg
      #markup += "<a class=\"fancybox\" rel=\"group\" href=\"/assets/scans/#{f}\" title=\"#{f}\">#{f}</a></br>"
      #a class="sb" href="/assets/scans/image-0001-00.jpg" title="Hey here's a caption">Image One</a>
      markup += "<a class=\"fancybox\" rel=\"group\" href=\"/assets/scans/#{f}\"><img src=\"/assets/scans/#{f}\" height=\"150\" width=\"150\"/ style=\"border:1px solid black\"></a>&nbsp;&nbsp; "
      #puts f
    end
    markup += "</br>"
    markup.html_safe
  end

  def print_images(scanid)
    markup = ""
    #scanid = "image-0001"
    scanid.gsub!("scan","image")
    dir = Rails.root.join("app","assets","images","scans")
    Dir.chdir(dir)
    sorted = Dir.glob("#{scanid}*.jpg").sort
    sorted.each do |f|
      markup += "<div style=\"page-break-after: always\">"
      markup += "<img class=\"contain\" src=\"/assets/scans/#{f}\" width=\"700\" height=\"840\" style=\"object-fit: contain;\">"
      markup += "</div>"
      #puts f
    end
    #markup += "</br>"
    markup.html_safe
  end

  def print_entries(scanid)
    solr = RSolr.connect :url => Blacklight.blacklight_yml[Rails.env]["url"]
    query = "scan_sm:\"#{scanid}\""
    solr_response = solr.get 'select', :params => {:fq=> query, :rows => 10, :fl => "entries_t, id, label_s" }
    entries = []
    if solr_response["response"] && solr_response["response"]["docs"].size > 0
      solr_response["response"]["docs"].each_with_index { |doc, i|
        if doc["entries_t"][0]
          obj_link = "\n[#{doc["label_s"]}](#{doc["id"]})"
          entries.append(obj_link + doc["entries_t"][0])
        end
      }
    end
    markdown(entries.join)
  end

  #used for objid AND scanid lookup in print_scan resource
  def headers_for_print(scanid)
    solr = RSolr.connect :url => Blacklight.blacklight_yml[Rails.env]["url"]
    query = "id:\"#{scanid}\""
    solr_response = solr.get 'select', :params => {:fq=> query, :rows => 10, :fl => "*" }

    headers = "<div><dl style=\"width:700\">"
    if solr_response["response"] && solr_response["response"]["docs"].size > 0
      solr_response["response"]["docs"].each_with_index { |doc, i|
        #solr_fields =  [doc["id"],doc["title_t"][0],doc["label_s"],doc["location_s"],doc["author_display"],doc[""]]
        headers += "<div style=\"font-weight: bold;\">ID:</div><div>#{doc['id']}</<div>"
        headers += "<div style=\"font-weight: bold;\">Title:</div><div>#{curry_array(doc['title_t'])}</div>" if doc["title_t"]
        headers += "<div style=\"font-weight: bold;\">Label:</div><div>#{doc['label_s']}</div>" if doc["label_s"]
        headers += "<div style=\"font-weight: bold;\">Location:</div><div>#{doc['location_s']}</div>" if doc["location_s"]
        headers += "<div style=\"font-weight: bold;\">Author:</div><div>#{doc['author_display']}</div>" if doc["author_display"]
        headers += "<div style=\"font-weight: bold;\">Related Scan:</div><div>#{curry_array(doc['scan_sm'])}</div>" if doc["scan_sm"]
        headers += "<div style=\"font-weight: bold;\">Scientific Name (GNRD):</div><div>#{curry_array(doc['gnrd_sm'])}</div>" if doc["gnrd_sm"]
        headers += "<div style=\"font-weight: bold;\">Current Sci Name:</div><div>#{curry_array(doc['csn_t'])}</div>" if doc["csn_t"]
        headers += "<div style=\"font-weight: bold;\">Current Vern Name:</div><div>#{curry_array(doc['cvn_t'])}</div>" if doc["cvn_t"]
        headers += "<div style=\"font-weight: bold;\">Historical Sci Name:</div><div>#{curry_array(doc['hsn_t'])}</div>" if doc["hsn_t"]
        headers += "<div style=\"font-weight: bold;\">Historical Vern Name:</div><div>#{curry_array(doc['hvn_t'])}</div>" if doc["hvn_t"]
        headers += "<div style=\"font-weight: bold;\">Identification Notes:</div><div>#{curry_array(doc['notes_t'])}</div>" if doc["notes_t"]
        headers += "<div style=\"font-weight: bold;\">Identification Sources:</div><div>#{curry_array(doc['sources_t'])}</div>" if doc["sources_t"]
        headers += "<div style=\"font-weight: bold;\">Scan Subject:</div><div>#{doc['subject_topic_s']}</div>" if doc["subject_topic_s"]
        headers += "<div style=\"font-weight: bold;\">Container:</div><div>#{doc['part_of_s']}</div>" if doc["part_of_s"]
        headers += "<div style=\"font-weight: bold;\">Recto:</div><div>#{doc['recto_s']}</div>" if strip_char(doc["recto_s"])
        headers += "<div style=\"font-weight: bold;\">Verso:</div><div>#{doc['verso_s']}</div>" if strip_char(doc["verso_s"])
        headers += "<div style=\"font-weight: bold;\">Photo:</div><div>#{doc['photo_s']}</div>" if strip_char(doc["photo_s"])
        headers += "<div style=\"font-weight: bold;\">Stamp:</div><div>#{doc['institutional_stamp_s']}</div>" if strip_char(doc["institutional_stamp_s"])
        #below: object only
        headers += "<div style=\"font-weight: bold;\">Notebook Header:</div><div>#{doc['subject_s']}</div>" if doc["subject_s"] && doc["object_type_s"]=="object"
        headers += "<div style=\"font-weight: bold;\">Description:</div><div>#{markdown(curry_array(doc['entries_t']))}</div>" if strip_char(doc["entries_t"]) && doc["object_type_s"]=="object"
      }
    end
    headers += "</dl></div>"
    headers.html_safe
  end

  def curry_array(array)
    s = ""
    array.each { |a|
      s+= a + "</br>"
    }
    s[0...-5]
  end

  def strip_char(s)
    return nil if s.nil?
    i = 0
    c = "\n"
    s[i] = "" if s[i]==c
    return nil if s.length==0
    s
  end

  def count_object_images
    markup = ""
    id = request.original_url.split("/").last.gsub("scan","image")
    dir = Rails.root.join("app","assets","images","scans")
    Dir.chdir(dir)
    sorted = Dir.glob("#{id}*.jpg").sort
    sorted.size
  end

  def get_thumbnail(s)
    #s = "http://localhost:3000/image-service/image-0001-00/full/150,150/0/default.jpg"
    s2  = s.split("/")[4] + ".jpg"
    s3 = "http://#{request.host_with_port}/assets/scans/#{s2}"

    return s3
  end

  def getfields(id,field)
    solr = RSolr.connect :url => Blacklight.blacklight_yml[Rails.env]["url"]
    query = "id:\"#{id}\""
    solr_response = solr.get 'select', :params => {:fq=> query, :rows => 1, :fl => "*" }

    found = true
    return_content = ""
    if solr_response["response"] && solr_response["response"]["docs"].size > 0
      solr_response["response"]["docs"].each_with_index { |doc, i|
        #puts doc.inspect
        field_sym = field.to_sym
        return_content = doc["#{field_sym}"] if doc["#{field_sym}"]
      }
    else
      found = false
    end
    return found, return_content
  end

  def updatedoc(id,field, content)
    solr = RSolr.connect :url => Blacklight.blacklight_yml[Rails.env]["url"]
    query = "id:\"#{id}\""
    solr_response = solr.get 'select', :params => {:fq=> query, :rows => 1, :fl => "*" }

    found = true
    return_content = ""
    if solr_response["response"] && solr_response["response"]["docs"].size > 0
      solr_response["response"]["docs"].each_with_index { |doc, i|
        #puts doc.inspect
        field_sym = field.to_sym
        docClone=doc.clone
        docClone["#{field_sym}"] = content
        docClone['timestamp'] = Time.now
        solr.add docClone
        solr.commit
      }
    else
      found = false
    end
    return found, return_content
  end

  def deletefield(id,field)
    solr = RSolr.connect :url => Blacklight.blacklight_yml[Rails.env]["url"]
    query = "id:\"#{id}\""
    solr_response = solr.get 'select', :params => {:fq=> query, :rows => 1, :fl => "*" }

    found = true
    return_content = ""
    if solr_response["response"] && solr_response["response"]["docs"].size > 0
      solr_response["response"]["docs"].each_with_index { |doc, i|
        #puts doc.inspect
        field_sym = field.to_sym
        docClone=doc.clone
        if docClone["#{field_sym}"].nil? == false
          docClone = docClone.except("#{field_sym}")
          docClone['timestamp'] = Time.now
          solr.add docClone
          solr.commit
        end
      }
    else
      found = false
    end
    return found, return_content
  end
end
