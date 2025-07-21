# frozen_string_literal: true

class ProductCardComponent < ViewComponent::Base
  def initialize(product:, show_discount: true, show_labels: true)
    @product = product
    @show_discount = show_discount
    @show_labels = show_labels
  end

  private

  attr_reader :product, :show_discount, :show_labels

  def product_image_url
    @product_image_url ||= begin
      # Extract image URL from meta_description field (temporary solution)
      if product.meta_description&.start_with?("IMAGE_URL:")
        product.meta_description.sub("IMAGE_URL:", "")
      else
        # Fallback to placeholder
        encoded_name = CGI.escape(product.name.truncate(20))
        "https://via.placeholder.com/300x300/f3f4f6/9ca3af?text=#{encoded_name}"
      end
    end
  end

  def discount_percentage
    @discount_percentage ||= begin
      return nil unless show_discount && default_variant&.on_sale?

      "#{default_variant.discount_percentage}%"
    end
  end

  def has_discount?
    @has_discount ||= default_variant&.on_sale? || false
  end

  def default_variant
    @default_variant ||= product.default_variant
  end

  def is_hit_product?
    return false unless show_labels

    # Hit if has 10+ reviews or created within last 30 days
    (product.reviews_count >= 10) || (product.created_at > 30.days.ago)
  end

  def price_display
    @price_display ||= begin
      return "Price not available" unless default_variant

      current_price = default_variant.price
      "from #{current_price.format(symbol: '', with_currency: true, decimal_mark: ' ')}"
    end
  end

  def original_price_display
    @original_price_display ||= begin
      return nil unless default_variant&.on_sale?

      default_variant.compare_at_price.format(symbol: "", with_currency: true, decimal_mark: " ")
    end
  end

  def category_label
    @category_label ||= begin
      category = product.categories.first
      return "COSMETICS" unless category

      category.name.upcase
    end
  end

  def product_path
    Rails.application.routes.url_helpers.product_path(product)
  rescue
    "/products/#{product.to_param}"
  end

  def heart_icon_svg
    <<~SVG
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"></path>
      </svg>
    SVG
  end
end
