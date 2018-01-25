class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout 'blacklight'

  protect_from_forgery with: :exception

  before_action :block_foreign_hosts

  def block_foreign_hosts
    puts "Remote_ip:#{request.remote_ip}"
    lines = Array.new
    whitelisted = whitelisted?(request.remote_ip)
    puts "Whitelisted:#{whitelisted}"
    return false if whitelisted
    redirect_to "https://britishart.yale.edu/" #unless request.remote_ip.start_with?("130.132")
  end

  def whitelisted?(ip)
    lines = Array.new
    File.open("#{Rails.root}/config/ip.txt").each { |line| lines << line.gsub("\n","") }
    #puts "Allowed:#{lines.inspect}"
    return true if lines.include?(ip)
    false
  end

end
