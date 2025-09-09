# frozen_string_literal: true

class Carts::AddItemService
  def self.call(cart:, product_variant:, quantity: 1)
    new(cart: cart, product_variant: product_variant, quantity: quantity).call
  end

  def initialize(cart:, product_variant:, quantity: 1)
    @cart = cart
    @product_variant = product_variant
    @quantity = quantity.to_i
    @errors = []
  end

  def call
    validate_inputs
    return failure_result if errors.any?

    ActiveRecord::Base.transaction do
      @cart_item = find_or_create_cart_item
      update_quantity
      @cart_item.save!
    end

    success_result
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Carts::AddItemService validation error: #{e.message}"
    @errors.push("We couldn't add this item to your cart. Please try again.")
    failure_result
  rescue => e
    Rails.logger.error "Carts::AddItemService unexpected error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @errors.push("Something went wrong. Please try again.")
    failure_result
  end

  private

  attr_reader :cart, :product_variant, :quantity, :errors

  def validate_inputs
    @errors.push("Cart is required") unless cart
    @errors.push("Product variant is required") unless product_variant

    return unless product_variant

    result = Carts::QuantityService.validate_quantity(quantity,
      product_variant: product_variant,
      existing_quantity: 0)

    @errors.concat(result.errors) if result.failure?
  end

  def find_or_create_cart_item
    cart.cart_items.find_or_initialize_by(product_variant: product_variant)
  end

  def update_quantity
    if @cart_item.persisted?
      result = Carts::QuantityService.validate_quantity(quantity,
        product_variant: product_variant,
        existing_quantity: @cart_item.quantity)

      if result.failure?
        @errors.concat(result.errors)
        return
      end

      @cart_item.quantity = @cart_item.quantity + quantity
    else
      @cart_item.quantity = quantity
    end
  end

  def success_result
    Carts::BaseResult.new(resource: @cart_item, cart: cart, success: true)
  end

  def failure_result
    Carts::BaseResult.new(errors: errors, success: false, cart: cart)
  end
end
