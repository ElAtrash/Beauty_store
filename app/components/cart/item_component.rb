# frozen_string_literal: true

class Cart::ItemComponent < ViewComponent::Base
  include Rails.application.routes.url_helpers

  def initialize(cart_item:)
    @cart_item = cart_item
  end

  private

  attr_reader :cart_item

  def product
    cart_item.product
  end

  def product_variant
    cart_item.product_variant
  end

  def featured_image
    product_variant.featured_image
  end

  def product_name
    product.name
  end

  def variant_display_name
    product_variant.try(:name).presence || product_variant.sku
  end

  def quantity
    cart_item.quantity
  end

  def total_price
    cart_item.total_price
  end

  def can_decrease_quantity?
    quantity > 1
  end

  def can_increase_quantity?
    return true unless product_variant.track_inventory?
    return true if product_variant.allow_backorder?

    quantity < product_variant.stock_quantity
  end

  def quantity_params(new_quantity)
    { cart_item: { quantity: [ new_quantity, 1 ].max } }
  end

  def decrease_quantity_params
    quantity_params(quantity - 1)
  end

  def increase_quantity_params
    quantity_params(quantity + 1)
  end
end
