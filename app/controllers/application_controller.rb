class ApplicationController < ActionController::Base
  ALLOWED_USERS = ["ermadmix","kab86","am539","bacref3"]
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout 'blacklight'

  protect_from_forgery with: :exception

  before_action :authenticate_user!, unless: :skip_cas
  before_action :verify_allowed_user, unless: :skip_cas
  skip_before_action :authenticate_user!, only: [:logout]
  skip_before_action :verify_allowed_user, only: [:logout]

  def skip_cas
    false
  end

  def verify_allowed_user
    return unless current_user
    netid = current_user.email.split('@').first
    return if ALLOWED_USERS.include?(netid)
    sign_out :user
    reset_session
    redirect_to "https://secure.its.yale.edu/cas/logout", allow_other_host: true
  end

  #deprecated
  def failed_auth_redirect
    deny_access unless ALLOWED_USERS.include?(session[:cas_user])
  end

  def deny_access
    render plain: "Your netid #{session[:cas_user]} is not authorized to access this page." and return
  end

  def after_sign_in_path_for(resource)
    flash.delete(:alert)
    super
  end

  def logout
    sign_out :user
    reset_session
    redirect_to "https://secure.its.yale.edu/cas/logout", allow_other_host: true
  end

  #deprecated
  def block_foreign_hosts
    puts "Remote_ip:#{request.remote_ip}"
    lines = Array.new
    whitelisted = whitelisted?(request.remote_ip)
    puts "Whitelisted:#{whitelisted}"
    return false if whitelisted
    #redirect_to "https://britishart.yale.edu/" #unless request.remote_ip.start_with?("130.132")
  end

  #deprecated
  def whitelisted?(ip)
    lines = Array.new
    File.open("#{Rails.root}/config/ip.txt").each { |line| lines << line.gsub("\n","") }
    #puts "Allowed:#{lines.inspect}"
    return true if lines.include?(ip)
    false
  end

end
