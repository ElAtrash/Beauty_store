module AuthenticationFlow
  extend ActiveSupport::Concern

  included do
    allow_unauthenticated_access only: %i[ new create ]
    rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to_rate_limit_page }
  end

  private

  def store_return_url
    session[:return_to] = params[:return_to] if params[:return_to].present?
  end

  def popup_return_url
    stored_location = session.delete(:return_to)
    stored_location || root_url
  end

  def handle_successful_authentication(user, success_message)
    start_new_session_for user

    respond_to do |format|
      format.html { redirect_to popup_return_url }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("auth_result",
          partial: "shared/auth_success",
          locals: { message: success_message, user: user }
        )
      end
    end
  end

  def handle_authentication_error(error_message, fallback_path = root_path)
    respond_to do |format|
      format.html { redirect_to fallback_path, alert: error_message }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("auth_result",
          partial: "shared/auth_error",
          locals: { message: error_message }
        )
      end
    end
  end

  def redirect_to_rate_limit_page
    if self.class.name == "SessionsController"
      redirect_to new_session_url, alert: t("auth.errors.rate_limit")
    elsif self.class.name == "RegistrationsController"
      redirect_to new_registration_url, alert: t("auth.errors.rate_limit")
    else
      redirect_to root_url, alert: t("auth.errors.rate_limit")
    end
  end
end
