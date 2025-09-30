# frozen_string_literal: true

class Carts::ClearService
  include BaseService

  def self.call(cart:)
    new(cart: cart).call
  end

  def initialize(cart:)
    @cart = cart
    @cleared_variants = []
    @cleared_items_count = 0
  end

  def call
    validate_required_params(cart: cart)
    return last_result if last_result&.failure?

    return success(
      cart: cart,
      cleared_variants: [],
      cleared_items_count: 0
    ) if cart.cart_items.empty?

    result = ActiveRecord::Base.transaction do
      prepare_clear_data
      clear_all_items
      cart.cart_items.reload

      success(
        cart: cart,
        cleared_variants: @cleared_variants,
        cleared_items_count: @cleared_items_count
      )
    end

    result || failure(@rollback_errors || [ "Failed to clear items" ], cart: cart)
  rescue => e
    log_error("unexpected error", e)
    failure(I18n.t("services.errors.something_went_wrong"), cart: cart)
  end

  private

  attr_reader :cart, :cleared_variants, :cleared_items_count

  def prepare_clear_data
    @cleared_variants = cart.cart_items.includes(:product_variant).map(&:product_variant)
    @cleared_items_count = cart.cart_items.count
  end

  def clear_all_items
    cart.cart_items.find_each do |cart_item|
      result = Carts::ItemUpdateService.set_quantity(cart_item, 0)
      unless result.success?
        @rollback_errors = result.errors
        log_error("Failed to clear item", StandardError.new(result.errors.join(", ")))
        raise ActiveRecord::Rollback, result.errors.join(", ")
      end
    end
  end
end
