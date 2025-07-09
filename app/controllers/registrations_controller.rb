class RegistrationsController < ApplicationController
  include AuthenticationFlow

  def new
    @user = User.new
  end

  def create
    store_return_url
    @user = User.new(user_params)

    if @user.save
      handle_successful_authentication(@user, t("auth.errors.account_created"))
    else
      handle_registration_errors
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :email_address,
      :password,
      :password_confirmation
    )
  end

  def handle_registration_errors
    errors = @user.errors.full_messages.join(", ")
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("auth_result",
          partial: "shared/auth_error",
          locals: { message: errors }
        )
      end
    end
  end
end
