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
    # Create new guest cart for post-logout shopping
    new_cart_token = create_guest_cart_on_logout

    # Clear sensitive checkout form data
    Checkout::FormStateService.clear_from_session(session)

    terminate_session

    # Set new guest cart token (disconnected from user cart)
    session[:cart_token] = new_cart_token if new_cart_token.present?

    redirect_to root_path
  end

  private

  def create_guest_cart_on_logout
    # Only create guest cart if user was logged in
    return nil unless Current.user.present?

    # Create fresh guest cart for post-logout shopping
    guest_cart = Cart.create!(user: nil)

    Rails.logger.info "SessionsController: Created guest cart #{guest_cart.session_token} on logout for #{Current.user.email_address}"

    guest_cart.session_token
  rescue => e
    Rails.logger.error "SessionsController: Failed to create guest cart on logout: #{e.message}"
    nil
  end
end
