# frozen_string_literal: true

class Carts::ItemUpdateService
  def self.call(cart_item, params:)
    new(cart_item, params: params).call
  end

  def self.set_quantity(cart_item, new_quantity)
    new(cart_item).set_quantity(new_quantity)
  end

  def initialize(cart_item, params: nil)
    @cart_item = cart_item
    @cart = cart_item.cart
    @errors = []
    @params = params
  end

  def call
    action_type, quantity_value = parse_params

    case action_type
    when :increment
      new_quantity = @cart_item.quantity + 1
      result = Carts::QuantityService.can_set_quantity?(@cart_item, new_quantity)
      return validate_and_handle_errors(result) if result.failure?

      update_quantity(new_quantity)
    when :decrement
      new_quantity = @cart_item.quantity - 1

      if new_quantity <= 0
        destroy_item
      else
        update_quantity(new_quantity)
      end
    when :set_quantity
      set_quantity(quantity_value)
    else
      @errors << "Invalid action type"
      failure_result
    end
  end

  def set_quantity(new_quantity)
    result = Carts::QuantityService.can_set_quantity?(@cart_item, new_quantity)
    return validate_and_handle_errors(result) if result.failure?

    if new_quantity.to_i <= 0
      destroy_item
    else
      update_quantity(new_quantity.to_i)
    end
  end

  private

  attr_reader :cart_item, :cart, :errors, :params

  def parse_params
    return [ :invalid, nil ] unless params

    if params[:cart_item]&.[](:quantity)
      [ :set_quantity, params[:cart_item][:quantity].to_i ]
    elsif params[:quantity_action] == "increment"
      [ :increment, nil ]
    elsif params[:quantity_action] == "decrement"
      [ :decrement, nil ]
    elsif params[:quantity].present?
      [ :set_quantity, params[:quantity].to_i ]
    else
      [ :invalid, nil ]
    end
  end

  def validate_and_handle_errors(result)
    @errors.concat(result.errors)
    failure_result
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
      BaseResult.new(cart: @cart, success: true)
    end
  end

  def execute_cart_operation(operation_type)
    ActiveRecord::Base.transaction do
      yield
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Carts::ItemUpdateService validation error: #{e.message}"
    @errors << "We couldn't #{operation_type} your cart item. Please try again."
    failure_result
  rescue => e
    Rails.logger.error "Carts::ItemUpdateService unexpected error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @errors << "Something went wrong. Please try again."
    failure_result
  end

  def success_result
    BaseResult.new(resource: @cart_item, cart: @cart, success: true)
  end

  def failure_result
    BaseResult.new(errors: @errors, success: false, cart: @cart)
  end
end
