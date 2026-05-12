class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  skip_before_action :verify_authenticity_token, only: :cas

  def cas
    auth = request.env["omniauth.auth"]

    Rails.logger.info "logging in"
    Rails.logger.info "auth netid: #{auth.uid}"
    #Rails.logger.info "session: #{session[:cas_user]}"

    unless ApplicationController::ALLOWED_USERS.include?(auth.uid)
      Rails.logger.info "#{auth.uid} not in ALLOWED_USERS"
      sign_out :user
      reset_session
      redirect_to "https://secure.its.yale.edu/cas/logout", allow_other_host: true
      return
    end

    @user = User.from_omniauth(auth)
    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
    else
      redirect_to root_path, alert: "Authentication failed."
    end
  end

  def failure
    redirect_to root_path, alert: "Authentication failed: #{failure_message}"
  end
end  

