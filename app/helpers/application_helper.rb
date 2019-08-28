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
      markup += "<img src=\"/assets/scans/#{f}\" width=\"670\"/ style=\"border:1px solid black\">"
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

  def headers_for_print(scanid)
    solr = RSolr.connect :url => Blacklight.blacklight_yml[Rails.env]["url"]
    query = "id:\"#{scanid}\""
    solr_response = solr.get 'select', :params => {:fq=> query, :rows => 10, :fl => "title_t, author_t" }
    headers = ""
    if solr_response["response"] && solr_response["response"]["docs"].size > 0
      solr_response["response"]["docs"].each_with_index { |doc, i|
        headers += "<p>#{scanid}</p>"
        headers += "<p>#{doc["title_t"][0]}</p>" if doc["title_t"][0]
        headers += "<p>#{doc["author_t"][0]}</p>" if doc["author_t"][0]
      }
    end
    headers.html_safe
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

end
