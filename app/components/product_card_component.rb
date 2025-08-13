# frozen_string_literal: true

class ProductCardComponent < ViewComponent::Base
  include Rails.application.routes.url_helpers

  with_collection_parameter :product

  IMAGE_VARIANT_SIZE = [ 300, 300 ].freeze

  def initialize(product:, show_discount: true, show_labels: true)
    @product = product
    @show_discount = show_discount
    @show_labels = show_labels
  end

  def product_image_url
    @product_image_url ||= begin
      image_attachment = find_image_attachment

      if image_attachment
        if image_attachment.content_type == "image/svg+xml"
          return rails_blob_url(image_attachment, only_path: false)
        end

        safe_image_variant_url(image_attachment)
      else
        placeholder_data_url
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

  def is_hit_product?
    return false unless show_labels

    product.hit_product?
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

  def product_url
    product_path(product)
  rescue
    "/products/#{product.to_param}"
  end

  private

  attr_reader :product, :show_discount, :show_labels

  def find_image_attachment
    return default_variant.featured_image if default_variant&.featured_image&.attached?
    return default_variant.images.first if default_variant&.images&.attached?
    return product.featured_image if product.featured_image&.attached?
    return product.images.first if product.images&.attached?

    nil
  end

  def default_variant
    @default_variant ||= product.default_variant
  end

  def safe_image_variant_url(attachment)
    begin
      rails_blob_url(
        attachment.variant(resize_to_fill: [ *IMAGE_VARIANT_SIZE, { gravity: :center } ]),
        only_path: false
      )
    rescue ArgumentError => e
      if e.message.include?("Missing host")
        rails_blob_path(
          attachment.variant(resize_to_fill: [ *IMAGE_VARIANT_SIZE, { gravity: :center } ])
        )
      else
        raise e
      end
    rescue => e
      rails_blob_url(attachment, only_path: false)
    end
  end

  def placeholder_data_url
    placeholder_svg = IconPath::ICONS[:product_placeholder]
    "data:image/svg+xml;base64,#{Base64.strict_encode64("<svg width=\"300\" height=\"300\" xmlns=\"http://www.w3.org/2000/svg\">#{placeholder_svg}</svg>")}"
  end
end
