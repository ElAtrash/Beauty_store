# frozen_string_literal: true

class CheckoutController < ApplicationController
  allow_unauthenticated_access

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
    @cart = current_cart
    @checkout_form = CheckoutForm.new(checkout_params)

    result = Checkout::ProcessOrderService.call(
      checkout_form: @checkout_form,
      cart: @cart,
      session: session
    )

    if result.success?
      redirect_to checkout_confirmation_path(result.resource.number),
                  notice: t("checkout.order_placed_successfully")
    else
      Checkout::ErrorResponseService.call(
        controller: self,
        result: result,
        cart: @cart,
        form: @checkout_form
      )
    end
  rescue => e
    Rails.logger.error "Order processing error: #{e.message}"
    result = BaseResult.new(success: false, errors: [ t("errors.something_went_wrong") ])
    Checkout::ErrorResponseService.call(
      controller: self,
      result: result,
      cart: @cart || current_cart,
      form: @checkout_form || CheckoutForm.new
    )
  end

  def update
    return head :ok unless params[:checkout_form].present?

    @checkout_form = Checkout::FormStateService.restore_from_session(session)
    Checkout::FormStateService.update_and_persist(@checkout_form, checkout_params, session)

    respond_to do |format|
      format.json { head :ok }
    end
  end

  def delivery_schedule
    @checkout_form = Checkout::FormStateService.restore_from_session(session)
    @delivery_method = delivery_method_param || @checkout_form.delivery_method

    Checkout::DeliveryMethodHandler.call(
      form: @checkout_form,
      delivery_method: @delivery_method
    )

    respond_to do |format|
      format.turbo_stream
    end
  end

  def delivery_summary
    @checkout_form = Checkout::FormStateService.restore_from_session(session)
    @delivery_method = delivery_method_param || @checkout_form.delivery_method

    Checkout::DeliveryMethodHandler.call(
      form: @checkout_form,
      delivery_method: @delivery_method,
      address_params: address_update_params
    )

    Checkout::FormStateService.persist_if_valid(@checkout_form, session)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def reorder
    result = Orders::ReorderService.call(
      order: @order,
      user: Current.user,
      session: session,
      cart_token: session[:cart_token]
    )

    if result.success?
      handle_successful_reorder(result)
    else
      handle_failed_reorder(result)
    end
  rescue => e
    Rails.logger.error "Reorder error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    handle_reorder_exception
  end

  private

  def checkout_params
    params.require(:checkout_form).permit(
      :email, :phone_number, :first_name, :last_name,
      :address_line_1, :address_line_2, :city, :landmarks,
      :delivery_method, :payment_method, :delivery_notes,
      :delivery_date, :delivery_time_slot
    )
  end

  def delivery_method_param
    params.permit(:delivery_method)[:delivery_method]
  end

  def address_update_params
    params.permit(:address_line_1, :address_line_2, :landmarks, :city).to_h
  end

  def validate_cart_presence
    validation_result = Checkout::CartValidationService.call(current_cart)

    unless validation_result.success?
      redirect_to root_path, alert: validation_result.errors.first
    end
  rescue => e
    Rails.logger.error "Cart validation error: #{e.message}"
    redirect_to root_path, alert: t("errors.something_went_wrong")
  end

  def setup_checkout_form
    return if performed?

    @checkout_form = Checkout::FormStateService.restore_from_session(session)
    @cart = current_cart

    validation_result = Checkout::CartValidationService.call(@cart)
    unless validation_result.success?
      redirect_to root_path, alert: validation_result.errors.first
    end
  rescue => e
    Rails.logger.error "Checkout form setup error: #{e.message}"
    redirect_to root_path, alert: t("errors.something_went_wrong")
  end

  def set_order
    @order = Order.find_by!(number: params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def handle_successful_reorder(result)
    message = result.metadata[:message]

    sync_result = Carts::SyncService.call(
      cart: result.cart,
      notification: { type: "success", message: message, delay: 4000 }
    )

    respond_to do |format|
      format.turbo_stream do
        render "shared/cart_sync", locals: {
          cart: sync_result.cart,
          variant: nil,
          cleared_variants: nil,
          notification: sync_result.notification,
          open_modal: true
        }
      end
      format.html do
        redirect_to checkout_confirmation_path(@order.number), notice: result.metadata[:message]
      end
    end
  end

  def handle_failed_reorder(result)
    respond_to do |format|
      format.turbo_stream { render "reorder_error", locals: { errors: result.errors } }
      format.html do
        redirect_to checkout_confirmation_path(@order.number), alert: result.errors.join(", ")
      end
    end
  end

  def handle_reorder_exception
    respond_to do |format|
      format.turbo_stream { render "reorder_error", locals: { errors: [ t("checkout.reorder.errors.something_went_wrong") ] } }
      format.html do
        redirect_to checkout_confirmation_path(@order.number), alert: t("checkout.reorder.errors.reorder_failed")
      end
    end
  end
end
