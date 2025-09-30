# frozen_string_literal: true

class Checkout::CartValidationService
  def self.call(cart)
    new(cart).call
  end

  def initialize(cart)
    @cart = cart
  end

  def call
    return invalid_result("checkout.cart_empty") if cart.nil?
    return invalid_result("checkout.cart_empty") unless cart.persisted?
    return invalid_result("checkout.cart_empty") if cart.cart_items.empty?
    return invalid_result("checkout.cart_empty") if cart.cart_items.sum(:quantity) == 0

    BaseResult.new(success: true)
  end

  private

  attr_reader :cart

  def invalid_result(translation_key)
    BaseResult.new(
      success: false,
      errors: [ I18n.t(translation_key) ],
      error_type: :validation
    )
  end
end
