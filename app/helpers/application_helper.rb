module ApplicationHelper

  def render_markdown options={}
    #markdown(options[:value][0])
    a = Array.new
    options[:value].each { |s| a.push(markdown(s)) }
    if a.length == 1
      a[1] = ""
      a[2] = ""
      a[3] = ""
    end
    if a.length == 2
      a[2] = ""
      a[3] = ""
    end
    if a.length == 3
      a[3] = ""
    end
    a[0] + a[1] + a[2] + a[3]
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
end
