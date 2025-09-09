# frozen_string_literal: true

class Carts::ItemUpdateService
  def self.increment(cart_item)
    new(cart_item).increment
  end

  def self.decrement(cart_item)
    new(cart_item).decrement
  end

  def self.set_quantity(cart_item, new_quantity)
    new(cart_item).set_quantity(new_quantity)
  end

  def self.add_more(cart_item, additional_quantity = 1)
    new(cart_item).add_more(additional_quantity)
  end

  def initialize(cart_item)
    @cart_item = cart_item
    @cart = cart_item.cart
    @errors = []
  end

  def increment
    validate_increment
    return failure_result if @errors.any?

    update_quantity(@cart_item.quantity + 1)
  end

  def decrement
    new_quantity = @cart_item.quantity - 1

    if new_quantity <= 0
      destroy_item
    else
      update_quantity(new_quantity)
    end
  end

  def set_quantity(new_quantity)
    result = Carts::QuantityService.can_set_quantity?(@cart_item, new_quantity)
    if result.failure?
      @errors.concat(result.errors)
      return failure_result
    end

    if new_quantity.to_i <= 0
      destroy_item
    else
      update_quantity(new_quantity.to_i)
    end
  end

  def add_more(additional_quantity = 1)
    result = Carts::QuantityService.validate_quantity(additional_quantity,
      product_variant: @cart_item.product_variant,
      existing_quantity: @cart_item.quantity)

    if result.failure?
      @errors.concat(result.errors)
      return failure_result
    end

    update_quantity(@cart_item.quantity + additional_quantity.to_i)
  end

  private

  attr_reader :cart_item, :cart, :errors

  def validate_increment
    result = Carts::QuantityService.can_increment?(@cart_item)
    @errors.concat(result.errors) if result.failure?
  end

  def update_quantity(new_quantity)
    execute_cart_operation("update") do
      @cart_item.update!(quantity: new_quantity)
      success_result
    end
  end

  def destroy_item
    execute_cart_operation("remove") do
      @cart_item.destroy!
      Carts::BaseResult.new(cart: @cart, success: true)
    end
  end

  def execute_cart_operation(operation_type)
    ActiveRecord::Base.transaction do
      result = yield
      @cart.cart_items.reload
      result
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Carts::ItemUpdateService validation error: #{e.message}"
    @errors.push("We couldn't #{operation_type} your cart item. Please try again.")
    failure_result
  rescue => e
    Rails.logger.error "Carts::ItemUpdateService unexpected error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @errors.push("Something went wrong. Please try again.")
    failure_result
  end

  def success_result
    Carts::BaseResult.new(resource: @cart_item, cart: @cart, success: true)
  end

  def failure_result
    Carts::BaseResult.new(errors: @errors, success: false, cart: @cart)
  end
end
