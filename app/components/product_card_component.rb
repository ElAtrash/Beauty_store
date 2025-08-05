# frozen_string_literal: true

class ProductCardComponent < ViewComponent::Base
  with_collection_parameter :product

  def initialize(product:, show_discount: true, show_labels: true)
    @product = product
    @show_discount = show_discount
    @show_labels = show_labels
  end

  private

  attr_reader :product, :show_discount, :show_labels

  def product_image_url
    @product_image_url ||= begin
      image_attachment = find_image_attachment

      if image_attachment
        # Use image variant for product cards (300x300 optimized)
        begin
          Rails.application.routes.url_helpers.rails_blob_url(
            image_attachment.variant(resize_to_fill: [ 300, 300, { gravity: :center } ]),
            only_path: false
          )
        rescue ArgumentError => e
          if e.message.include?("Missing host")
            Rails.application.routes.url_helpers.rails_blob_path(
              image_attachment.variant(resize_to_fill: [ 300, 300, { gravity: :center } ])
            )
          else
            raise e
          end
        end
      else
        # Fallback to local placeholder (avoiding external DNS issues)
        encoded_name = CGI.escape(product.name.truncate(20))
        "data:image/svg+xml;base64,#{Base64.strict_encode64(generate_placeholder_svg(encoded_name))}"
      end
    end
  end

  def find_image_attachment
    return default_variant.featured_image if default_variant&.featured_image&.attached?
    return default_variant.images.first if default_variant&.images&.attached?
    return product.featured_image if product.featured_image&.attached?
    return product.images.first if product.images&.attached?

    nil
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

  def generate_placeholder_svg(text)
    <<~SVG
      <svg width="300" height="300" xmlns="http://www.w3.org/2000/svg">
        <rect width="300" height="300" fill="#f3f4f6"/>
        <text x="150" y="150" font-family="Arial, sans-serif" font-size="14" fill="#9ca3af" text-anchor="middle" dominant-baseline="middle">#{CGI.unescapeHTML(text)}</text>
      </svg>
    SVG
  end
end
