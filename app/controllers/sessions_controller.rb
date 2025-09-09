class SessionsController < ApplicationController
  include AuthenticationFlow

  def new
    redirect_to root_path
  end

  def create
    store_return_url

    if user = User.authenticate_by(params.permit(:email_address, :password))
      handle_successful_authentication(user, t("auth.errors.signed_in"))
    else
      handle_authentication_error(t("auth.errors.invalid_credentials"), new_session_path)
    end
  end

  def destroy
    session[:cart_token] = nil
    terminate_session
    redirect_to root_path
  end
end
