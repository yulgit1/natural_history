class PrintScanController < ApplicationController
  include ApplicationHelper
  def show
    @scanid = params[:scan]
    @entries = print_entries(@scanid)
    render layout: false
  end

  def object
    @objid = params[:object]
    render layout: false
  end
end