# frozen_string_literal: true

class Carts::ItemUpdateService
  include BaseService

  def self.call(cart_item, params:)
    new(cart_item, params: params).call
  end

  def self.set_quantity(cart_item, new_quantity)
    new(cart_item).set_quantity(new_quantity)
  end

  def initialize(cart_item, params: nil)
    @cart_item = cart_item
    @cart = cart_item.cart
    @params = params
  end

  def call
    action_type, quantity_value = parse_params

    case action_type
    when :increment
      increment_quantity
    when :decrement
      decrement_quantity
    when :set_quantity
      set_quantity(quantity_value)
    else
      failure(I18n.t("services.cart_item.invalid_action"), cart: cart)
    end
  end

  def set_quantity(new_quantity)
    result = Carts::QuantityService.can_set_quantity?(cart_item, new_quantity)
    return failure(result.errors, cart: cart) if result.failure?

    if new_quantity.to_i <= 0
      destroy_item
    else
      update_quantity(new_quantity.to_i)
    end
  end

  private

  attr_reader :cart_item, :cart, :params

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

  def increment_quantity
    new_quantity = cart_item.quantity + 1
    result = Carts::QuantityService.can_set_quantity?(cart_item, new_quantity)
    return failure(result.errors, cart: cart) if result.failure?

    update_quantity(new_quantity)
  end

  def decrement_quantity
    new_quantity = cart_item.quantity - 1

    if new_quantity <= 0
      destroy_item
    else
      update_quantity(new_quantity)
    end
  end

  def update_quantity(new_quantity)
    ActiveRecord::Base.transaction do
      cart_item.update!(quantity: new_quantity)
      success(resource: cart_item, cart: cart)
    end
  rescue ActiveRecord::RecordInvalid => e
    log_error("validation error", e)
    failure(I18n.t("services.cart_item.update_failed"), cart: cart)
  rescue => e
    log_error("unexpected error", e)
    failure(I18n.t("services.errors.something_went_wrong"), cart: cart)
  end

  def destroy_item
    ActiveRecord::Base.transaction do
      cart_item.destroy!
      success(cart: cart)
    end
  rescue ActiveRecord::RecordInvalid => e
    log_error("validation error", e)
    failure(I18n.t("services.cart_item.remove_failed"), cart: cart)
  rescue => e
    log_error("unexpected error", e)
    failure(I18n.t("services.errors.something_went_wrong"), cart: cart)
  end
end
