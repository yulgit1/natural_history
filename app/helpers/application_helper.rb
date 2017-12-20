module ApplicationHelper

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
end
