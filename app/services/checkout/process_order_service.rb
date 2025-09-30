
# frozen_string_literal: true

class Checkout::ProcessOrderService
  def self.call(**args)
    new(**args).call
  end

  def initialize(checkout_form:, cart:, session:)
    @checkout_form = checkout_form
    @cart = cart
    @session = session
  end

  def call
    return failure(I18n.t("services.errors.cart_required")) unless cart
    return failure(I18n.t("services.errors.cart_empty")) if cart.cart_items.empty?
    return failure(I18n.t("services.errors.checkout_form_required")) unless checkout_form

    unless checkout_form.valid?
      checkout_form.persist_to_session(session)
      return validation_failure(checkout_form.errors.full_messages)
    end

    checkout_form.persist_to_session(session)

    result = Orders::CreateService.call(cart: cart, customer_info: checkout_form.to_h)

    if result.success?
      clear_cart_and_session(result)
    else
      service_failure(result.errors)
    end
  end

  private

  attr_reader :checkout_form, :cart, :session

  def clear_cart_and_session(order_result)
    clear_cart_result = Carts::ClearService.call(cart: cart)
    checkout_form.clear_from_session(session)

    unless clear_cart_result.success?
      Rails.logger.error "Failed to clear cart after order creation: #{clear_cart_result.errors.join(', ')}"
    end

    success(resource: order_result.resource, order: order_result.order)
  end

  def success(resource: nil, order: nil, **metadata)
    BaseResult.new(
      success: true,
      resource: resource,
      order: order,
      **metadata
    )
  end

  def failure(errors, **metadata)
    BaseResult.new(
      success: false,
      errors: Array(errors),
      **metadata
    )
  end

  def validation_failure(errors)
    BaseResult.new(
      success: false,
      errors: errors,
      error_type: :validation
    )
  end

  def service_failure(errors)
    BaseResult.new(
      success: false,
      errors: errors,
      error_type: :service
    )
  end
end
