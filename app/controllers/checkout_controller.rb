# frozen_string_literal: true

class CheckoutController < ApplicationController
  allow_unauthenticated_access

  rescue_from StandardError, with: :handle_unexpected_error
  rescue_from ActionController::UnknownFormat, with: :handle_unknown_format

  before_action :validate_cart_presence, only: [ :new, :create ]
  before_action :setup_checkout_form, only: [ :new, :delivery_schedule, :delivery_summary ]
  before_action :set_order, only: [ :show, :reorder ]

  def show
    redirect_to root_path, alert: t("checkout.order_not_found") unless @order
  end

  def new
    # Form and cart are set up by before_action
  end

  def create
    # Restore form from session (includes address from modal selection)
    if Current.user
      @checkout_form = CheckoutForm.from_user(Current.user, session)
    else
      @checkout_form = Checkout::FormStateService.restore_from_session(session)
    end

    # Overlay submitted form params (user-filled fields)
    @checkout_form.assign_attributes(checkout_params)

    result = Checkout::ProcessOrderService.call(
      checkout_form: @checkout_form,
      cart: current_cart,
      session: session
    )

    if result.success?
      redirect_to checkout_confirmation_path(result.resource.number),
                  notice: t("checkout.order_placed_successfully")
    else
      @cart = current_cart
      Checkout::ErrorResponseService.call(
        controller: self,
        result: result,
        cart: @cart,
        form: @checkout_form
      )
    end
  end

  def update
    return head :ok unless params[:checkout_form].present?

    @checkout_form = Checkout::FormStateService.restore_from_session(session)
    Checkout::FormStateService.update_and_persist(@checkout_form, checkout_params, session)

    respond_to { |format| format.json { head :ok } }
  end

  def delivery_schedule
    update_delivery_context
    respond_to { |format| format.turbo_stream }
  end

  def delivery_summary
    update_delivery_context(
      persist: true,
      address_params: address_update_params,
      selected_address_id: delivery_summary_params[:selected_address_id]
    )
    respond_to { |format| format.turbo_stream }
  end

  def reorder
    result = Orders::ReorderService.call(
      order: @order,
      user: Current.user,
      session: session,
      cart_token: session[ApplicationController::CART_TOKEN_KEY]
    )

    responder = ReorderResponder.new(self, @order)

    if result.success?
      responder.respond_with_success(result)
    else
      responder.respond_with_failure(result)
    end
  end

  private

  def update_delivery_context(persist: false, address_params: {}, selected_address_id: nil)
    @delivery_method = delivery_method_param || @checkout_form.delivery_method

    # Update selected address ID if provided
    if selected_address_id.present? && Current.user
      address = Current.user.addresses.find_by(id: selected_address_id)
      if address
        @checkout_form.populate_from_address(address)
      else
        @checkout_form.selected_address_id = selected_address_id
      end
    end

    Checkout::DeliveryMethodHandler.call(
      form: @checkout_form,
      delivery_method: @delivery_method,
      address_params: address_params
    )

    Checkout::FormStateService.persist_if_valid(@checkout_form, session) if persist
  end

  def checkout_params
    params.require(:checkout_form).permit(
      :email, :phone_number, :first_name, :last_name, :address_line_1,
      :address_line_2, :city, :governorate, :landmarks, :delivery_method,
      :payment_method, :delivery_notes, :delivery_date, :delivery_time_slot,
      :save_address_as_default, :save_profile_info, :selected_address_id
    )
  end

  def delivery_summary_params
    params.permit(:delivery_method, :address_line_1, :address_line_2, :landmarks, :city, :selected_address_id)
  end

  def delivery_method_param
    delivery_summary_params[:delivery_method]
  end

  def address_update_params
    delivery_summary_params.slice(:address_line_1, :address_line_2, :landmarks, :city).to_h
  end

  def validate_cart_presence
    validation_result = Checkout::CartValidationService.call(current_cart)
    handle_cart_validation_failure(validation_result) unless validation_result.success?
  end

  def setup_checkout_form
    return if performed?

    if Current.user
      @checkout_form = CheckoutForm.from_user(Current.user, session)
    else
      @checkout_form = Checkout::FormStateService.restore_from_session(session)
    end

    @cart = current_cart
  end

  def handle_cart_validation_failure(result)
    redirect_to root_path, alert: result.errors.first
  end

  def set_order
    @order = Order.find_by!(number: params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def handle_unexpected_error(exception)
    Rails.logger.error "#{exception.class}: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")

    @cart ||= begin
      current_cart
    rescue StandardError => e
      Rails.logger.error "Failed to load cart in error handler: #{e.message}"
      nil
    end
    @checkout_form ||= CheckoutForm.new

    case action_name
    when "create"
      result = BaseResult.new(success: false, errors: [ t("errors.something_went_wrong") ])
      Checkout::ErrorResponseService.call(controller: self, result: result, cart: @cart, form: @checkout_form)
    when "reorder"
      ReorderResponder.new(self, @order).respond_with_exception
    else
      redirect_to root_path, alert: t("errors.something_went_wrong")
    end
  end

  def handle_unknown_format(_exception)
    head :not_acceptable
  end
end
