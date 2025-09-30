# frozen_string_literal: true

class Carts::AddItemService
  include BaseService

  def self.call(cart:, product_variant:, quantity: 1)
    new(cart: cart, product_variant: product_variant, quantity: quantity).call
  end

  def initialize(cart:, product_variant:, quantity: 1)
    @cart = cart
    @product_variant = product_variant
    @quantity = quantity.to_i
  end

  def call
    validate_required_params(cart: cart, product_variant: product_variant)
    return last_result if last_result&.failure?

    validate_quantity_rules
    return last_result if last_result&.failure?

    ActiveRecord::Base.transaction do
      @cart_item = cart.cart_items.find_or_initialize_by(product_variant: product_variant)
      update_cart_item_quantity
      @cart_item.save!
      success(resource: @cart_item, cart: cart)
    end
  rescue ActiveRecord::RecordInvalid => e
    log_error("validation error", e)
    failure(I18n.t("services.errors.cart_item_add_failed"), cart: cart)
  rescue => e
    log_error("unexpected error", e)
    failure(I18n.t("services.errors.something_went_wrong"), cart: cart)
  end

  private

  attr_reader :cart, :product_variant, :quantity

  def validate_quantity_rules
    existing_quantity = cart.cart_items.find_by(product_variant: product_variant)&.quantity || 0

    result = Carts::QuantityService.validate_quantity(
      quantity,
      product_variant: product_variant,
      existing_quantity: existing_quantity
    )

    @last_result = result if result.failure?
  end

  def update_cart_item_quantity
    if @cart_item.persisted?
      @cart_item.quantity += quantity
    else
      @cart_item.quantity = quantity
    end
  end
end
