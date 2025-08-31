# frozen_string_literal: true

class Products::ProductInfoComponent < ViewComponent::Base
  include DiscountBadgeHelper

  def initialize(product:, product_data:)
    @product = product
    @product_data = product_data
  end

  delegate :product_info, :variant_options, :price_info, :stock_info, to: :product_data

  private

  attr_reader :product, :product_data

  def formatted_current_price
    helpers.format_price(price_info[:current_cents], price_info[:currency])
  end

  def formatted_original_price
    helpers.format_price(price_info[:original_cents], price_info[:currency])
  end

  def discount_badge
    # Use centralized helper - price_info contains discount_percentage
    discount_badge_text_from_percentage(price_info[:discount_percentage])
  end

  def stock_status
    return "out_of_stock" unless stock_info[:available]
    stock_info[:quantity] <= 5 ? "low_stock" : "available"
  end

  def add_to_cart_action
    stock_info[:available] ? "addToCart" : "notifyOutOfStock"
  end

  def add_to_cart_label
    stock_info[:available] ? "ADD TO CART" : "NOTIFY ME"
  end

  # Helper method for when we only have percentage data, not variant object
  def discount_badge_text_from_percentage(percentage)
    return nil unless percentage && percentage > 0
    "#{percentage}%"
  end
end
