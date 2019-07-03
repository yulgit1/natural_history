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
      markup += "<a class=\"sb\" href=\"/assets/scans/#{f}\" title=\"#{f}\">#{f}</a></br>"
      #a class="sb" href="/assets/scans/image-0001-00.jpg" title="Hey here's a caption">Image One</a>
      #puts f
    end
    markup.html_safe
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
    s3 = "http://localhost:3000/assets/scans/#{s2}"

    return s3
  end

end
