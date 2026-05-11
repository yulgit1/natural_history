class ApplicationController < ActionController::Base
  ALLOWED_USERS = ["ermadmix", "kab86","am539","bacref3"]
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout 'blacklight'

  protect_from_forgery with: :exception

  before_action :authenticate_user!
  
  #before_action :authenticate_user, unless: :skip_cas
  #before_action :failed_auth_redirect
  ##before_action :block_foreign_hosts, :authenticate_user!
  #before_action :block_foreign_hosts
  def skip_cas
    # Define conditions for skipping CAS authentication, if any
    false
  end

  def failed_auth_redirect
    deny_access unless ALLOWED_USERS.include?(session[:cas_user])
  end

  def deny_access
    render plain: "Your netid #{session[:cas_user]} is not authorized to access this page." and return
  end

  def logout
    sign_out current_user
    redirect_to "https://secure.its.yale.edu/cas/logout", allow_other_host: true
  end
  def block_foreign_hosts
    puts "Remote_ip:#{request.remote_ip}"
    lines = Array.new
    whitelisted = whitelisted?(request.remote_ip)
    puts "Whitelisted:#{whitelisted}"
    return false if whitelisted
    #redirect_to "https://britishart.yale.edu/" #unless request.remote_ip.start_with?("130.132")
  end

  def whitelisted?(ip)
    lines = Array.new
    File.open("#{Rails.root}/config/ip.txt").each { |line| lines << line.gsub("\n","") }
    #puts "Allowed:#{lines.inspect}"
    return true if lines.include?(ip)
    false
  end

end
