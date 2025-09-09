# frozen_string_literal: true

class Cart::PopupComponent < ViewComponent::Base
  def initialize(cart:)
    @cart = cart
  end

  def empty_cart?
    cart.blank? || cart.empty?
  end

  def header_count_text
    cart&.display_quantity_text || ""
  end

  def cart_items
    return [] if empty_cart?

    cart.ordered_items
  end

  def formatted_total_price
    return "$0.00" if empty_cart?

    cart.formatted_total
  end

  private

  attr_reader :cart
end
