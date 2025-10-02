# frozen_string_literal: true

class ReorderResponder
  def initialize(controller, order)
    @controller = controller
    @order = order
  end

  def respond_with_success(result)
    message = result.metadata[:message]

    populate_checkout_session_from_order if should_prefill_from_order?

    sync_result = Carts::SyncService.call(
      cart: result.cart,
      notification: { type: "success", message: message, delay: 4000 }
    )

    @controller.respond_to do |format|
      format.turbo_stream do
        @controller.render "shared/cart_sync", locals: {
          cart: sync_result.cart,
          variant: nil,
          cleared_variants: nil,
          notification: sync_result.notification,
          open_modal: true
        }
      end
      format.html do
        @controller.redirect_to @controller.checkout_confirmation_path(@order.number),
          notice: result.metadata[:message]
      end
    end
  end

  def respond_with_failure(result)
    @controller.respond_to do |format|
      format.turbo_stream do
        @controller.render "reorder_error", locals: { errors: result.errors }
      end
      format.html do
        @controller.redirect_to @controller.checkout_confirmation_path(@order.number),
          alert: result.errors.join(", ")
      end
    end
  end

  def respond_with_exception
    return redirect_to_root_with_error unless @order

    @controller.respond_to do |format|
      format.turbo_stream do
        @controller.render "reorder_error", locals: { errors: [ I18n.t("checkout.reorder.errors.something_went_wrong") ] }
      end
      format.html do
        @controller.redirect_to @controller.checkout_confirmation_path(@order.number),
          alert: I18n.t("checkout.reorder.errors.reorder_failed")
      end
    end
  end

  private

  def redirect_to_root_with_error
    @controller.redirect_to @controller.root_path,
      alert: I18n.t("checkout.reorder.errors.reorder_failed")
  end

  # We only prefill when:
  # 1. Order exists
  # 2. No active checkout session (respects current user intent)
  # 3. User has no saved default address (respects saved preferences)
  def should_prefill_from_order?
    return false unless @order
    return false if @controller.session[Checkout::FormStateService::CHECKOUT_FORM_DATA_KEY].present?

    current_user = current_user_from_controller
    return true unless current_user
    return true unless current_user.customer_profile&.has_default_address? # No saved address - prefill

    false
  end

  def current_user_from_controller
    # Try multiple approaches to get current user for maximum compatibility
    return Current.user if defined?(Current) && Current.respond_to?(:user)
    return @controller.current_user if @controller.respond_to?(:current_user, true)
    nil
  end

  # Priority order for checkout prefill:
  # 1. Existing session data (active checkout) - NEVER overwritten
  # 2. User saved profile (has_default_address?) - Takes precedence
  # 3. Last order data (reorder context) - This method
  # 4. Empty form - Final fallback
  def populate_checkout_session_from_order
    session_data = {
      email: @order.email,
      phone_number: normalize_phone(@order.phone_number),
      first_name: @order.shipping_address["first_name"],
      last_name: @order.shipping_address["last_name"],
      address_line_1: @order.shipping_address["address_line_1"],
      address_line_2: @order.shipping_address["address_line_2"],
      city: @order.shipping_address["city"],
      governorate: @order.shipping_address["governorate"],
      landmarks: @order.shipping_address["landmarks"],
      delivery_method: @order.delivery_method
    }.compact

    @controller.session[Checkout::FormStateService::CHECKOUT_FORM_DATA_KEY] = session_data
  end

  def normalize_phone(phone)
    return "" if phone.blank?
    phone.gsub(/\D/, "").sub(/^961/, "")
  end
end
