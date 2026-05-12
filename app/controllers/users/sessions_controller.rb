class Users::SessionsController < Devise::SessionsController
  skip_before_action :authenticate_user!, raise: false
  def new
    redirect_to user_cas_omniauth_authorize_path
  end

     def destroy
       puts "in destroy"
      sign_out current_user
      sign_out :user
      reset_session
      redirect_to "https://secure.its.yale.edu/cas/logout", allow_other_host: true
    end
end
