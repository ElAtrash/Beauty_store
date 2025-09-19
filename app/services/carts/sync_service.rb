# frozen_string_literal: true

class Carts::SyncService
  def self.call(cart:, notification: nil, variant: nil, cleared_variants: nil)
    new(cart: cart, notification: notification, variant: variant, cleared_variants: cleared_variants).call
  end

  def initialize(cart:, notification: nil, variant: nil, cleared_variants: nil)
    @cart = cart
    @notification = notification
    @variant = variant
    @cleared_variants = cleared_variants
  end

  def call
    @cart&.reload

    BaseResult.new(
      success: true,
      cart: @cart,
      notification: @notification,
      variant: @variant,
      cleared_variants: @cleared_variants,
      cart_summary_data: cart_summary_data
    )
  end

  private

  def cart_summary_data
    return { total_quantity: 0, total_price: Money.new(0), items_count: 0 } unless @cart

    {
      total_quantity: @cart.total_quantity || 0,
      total_price: @cart.total_price || Money.new(0),
      items_count: @cart.cart_items.count || 0
    }
  end

  attr_reader :cart, :notification, :variant, :cleared_variants
end
