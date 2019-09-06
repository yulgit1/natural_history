class PrintScanController < ApplicationController
  include ApplicationHelper

  before_action :geteditpw, only: [:confirm]

  def geteditpw
    @setpw = File.open(Rails.root.join("config","editpw.txt")).read
    @setpw = @setpw.strip
  end
  def show
    @scanid = params[:scan]
    @entries = print_entries(@scanid)
    render layout: false
  end

  def object
    @objid = params[:object]
    render layout: false
  end

  def edit
  end

  def confirm
    @id = params[:id]
    @field = params[:field]
    @edittype = params[:edittype]
    @content = params[:content]
    @pw = params[:pw]

    if @pw == @setpw
      @badpw = false
      @found, @existing_content = getfields(@id,@field)
      if @edittype == "append" && @existing_content.kind_of?(Array)
        new_content = Array.new
        new_content.push(@content)
        @content = @existing_content + new_content
        @existing_content
      end
    else
      @badpw = true
    end
  end

  def submit
    @id = params[:id]
    @field = params[:field]
    @content = params[:content]
    @replaced = params[:replaced]
    updatedoc(@id,@field,@content)
  end

  def solr_lookup
    id = params[:id]
    field = params[:field]
    #puts id
    #puts field
    solr = RSolr.connect :url => Blacklight.blacklight_yml[Rails.env]["url"]
    query = "id:\"#{id}\""
    solr_response = solr.get 'select', :params => {:fq=> query, :rows => 1, :fl => "*" }

    content = ""
    if solr_response["response"] && solr_response["response"]["docs"].size > 0
      solr_response["response"]["docs"].each_with_index { |doc, i|
        #puts doc
        field_sym = field.to_sym
        content = doc["#{field_sym}"]
        puts content
      }
    end

    render :plain => content
  end
end