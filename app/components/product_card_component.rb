# frozen_string_literal: true

class ProductCardComponent < CollectionComponent
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include DiscountBadgeHelper

  with_collection_parameter :product

  with_options to: :product do
    delegate :name, :subtitle, :slug, :id, :reviews_count, :hit_product?, :all_variants_out_of_stock?
  end

  def initialize(product:, show_discount: true, show_labels: true)
    @product = product
    @show_discount = show_discount
    @show_labels = show_labels
  end

  def product_url
    product_path(product)
  rescue StandardError
    "/products/#{product.to_param}"
  end

  def wishlist_data
    {
      controller: "wishlist",
      action: "click->wishlist#toggle",
      wishlist_product_id_value: product.id
    }
  end

  def image_url
    @image_url ||= build_image_url
  end

  def image_classes
    tailwind_variants(
      "w-full h-full object-cover transition-all duration-300 group-hover:scale-105",
      variants: {
        all_variants_out_of_stock? => "grayscale opacity-75"
      }
    )
  end

  def badges
    @badges ||= build_badges
  end

  def show_badges?
    show_labels && badges.any?
  end

  def price_display
    return "Price not available" unless default_variant

    price = default_variant.price
    "from #{price.format(symbol: '', with_currency: true, decimal_mark: ' ')}"
  end

  def original_price_display
    return nil unless default_variant&.on_sale? && !all_variants_out_of_stock?

    default_variant.compare_at_price.format(symbol: "", with_currency: true, decimal_mark: " ")
  end

  def price_classes
    tailwind_variants(
      "font-bold transition-colors duration-200",
      variants: {
        all_variants_out_of_stock? => "text-gray-400"
      }
    )
  end

  private

  attr_reader :product, :show_discount, :show_labels

  def default_variant
    @default_variant ||= product.default_variant
  end

  def build_image_url
    attachment = [
      default_variant&.featured_image, default_variant&.images&.first
    ].find { |img| img&.attached? }

    if attachment
      gallery_image = Products::GalleryImage.new(
        attachment: attachment,
        type: :product_card
      )
      gallery_image.url(:medium)
    else
      placeholder_image = Products::GalleryImage.new(
        attachment: nil,
        type: :placeholder
      )
      placeholder_image.url(:medium)
    end
  rescue StandardError
    Products::GalleryImage.new(attachment: nil, type: :placeholder).url(:medium)
  end

  def build_badges
    return [ badge_for(:out_of_stock) ] if all_variants_out_of_stock?

    [].tap do |arr|
      arr << badge_for(:discount) if show_discount && default_variant&.on_sale?
      arr << badge_for(:hit) if show_labels && hit_product?
    end
  end

  def badge_for(type)
    case type
    when :out_of_stock
      { text: "OUT OF STOCK", classes: "bg-gray-800 text-white text-xs font-bold px-2 py-1 rounded" }
    when :discount
      discount_badge_data(default_variant)
    when :hit
      { text: "HIT", classes: "bg-yellow-400 text-black text-xs font-bold p-1" }
    end
  end
end
