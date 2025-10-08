
# frozen_string_literal: true

class Checkout::ProcessOrderService
  include BaseService

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

    persist_user_data_from_order(order_result.order)

    success(resource: order_result.resource, order: order_result.order)
  end

  def persist_user_data_from_order(order)
    return unless order.user&.persisted?

    save_delivery_address(order) if checkout_form.save_address_as_default
    update_user_basic_info(order) if checkout_form.save_profile_info
  rescue StandardError => e
    Rails.logger.error "Failed to persist user data from order: #{e.message}"
  end

  def save_delivery_address(order)
    return unless order.courier?

    # Create Address record instead of JSONB storage
    address_attributes = {
      label: determine_address_label(order),
      address_line_1: order.shipping_address["address_line_1"],
      address_line_2: order.shipping_address["address_line_2"],
      city: order.shipping_address["city"],
      governorate: order.shipping_address["governorate"],
      landmarks: order.shipping_address["landmarks"],
      phone_number: order.phone_number,
      default: true # Save as default when checkbox is checked
    }

    order.user.addresses.create!(address_attributes)
  end

  def determine_address_label(order)
    # Check if user already has a "Home" address
    if order.user.addresses.active.where(label: "Home").exists?
      # Generate unique label: "Home 2", "Home 3", etc.
      count = order.user.addresses.active.where("label LIKE ?", "Home%").count + 1
      count == 1 ? "Home" : "Home #{count}"
    else
      "Home"
    end
  end

  def update_user_basic_info(order)
    return unless order.shipping_address.present?

    user = order.user
    shipping = order.shipping_address

    updates = {
      first_name: shipping["first_name"],
      last_name: shipping["last_name"],
      phone_number: order.phone_number,
      city: shipping["city"],
      governorate: shipping["governorate"]
    }.select { |key, value| user.public_send(key).blank? && value.present? }

    user.update(updates) if updates.any?
  end
end
