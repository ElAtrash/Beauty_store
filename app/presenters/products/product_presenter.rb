# frozen_string_literal: true

module Products
  class ProductPresenter
    def initialize(product, selected_variant: nil)
      @product = product
      @selected_variant = selected_variant || product.default_variant
    end

    def build_display_data
      ProductDisplayData.new(
        product_info: build_product_info,
        default_variant: build_variant_data(@selected_variant),
        all_variants: build_all_variants_data,
        variant_images: build_variant_images_mapping,
        price_matrix: build_price_matrix,
        stock_matrix: build_stock_matrix,
        variant_options: build_variant_options
      )
    end

    private

    attr_reader :product, :selected_variant

    def build_product_info
      ProductInfo.new(
        name: product.name,
        subtitle: product.subtitle,
        brand_name: product.brand&.name || "Beauty Store",
        reviews_count: product.reviews_count,
        rating: product.average_rating
      )
    end

    def build_variant_data(variant)
      return nil unless variant

      {
        id: variant.id,
        name: variant.name,
        color: variant.color,
        size_value: variant.size_value,
        size_unit: variant.size_unit,
        size_type: variant.size_type,
        size_key: build_size_key(variant),
        sku: variant.sku
      }
    end

    def build_all_variants_data
      product.product_variants.includes(:featured_image_attachment).map do |variant|
        build_variant_data(variant)
      end
    end

    def build_variant_images_mapping
      mapping = {}

      default_images = build_product_images

      product.product_variants.includes(:featured_image_attachment).each do |variant|
        variant_images = []

        if variant.featured_image.attached?
          variant_images << build_gallery_image(variant.featured_image, :variant, variant)
        end

        # For now, also include product's general images
        # Future: could filter images based on variant attributes
        variant_images.concat(default_images)

        mapping[variant.id] = variant_images.uniq { |img| img.attachment }
      end

      # Ensure default variant mapping exists
      if selected_variant
        mapping[selected_variant.id] ||= default_images
      end

      mapping
    end

    def build_price_matrix
      matrix = {}

      product.product_variants.each do |variant|
        matrix[variant.id] = build_price_info(variant)
      end

      matrix
    end

    def build_stock_matrix
      matrix = {}

      product.product_variants.each do |variant|
        matrix[variant.id] = build_stock_info(variant)
      end

      matrix
    end

    def build_variant_options
      {
        colors: build_color_options,
        sizes: build_size_options
      }
    end

    def build_price_info(variant)
      return PriceInfo.new(current: "Price not available", on_sale: false) unless variant

      if variant.on_sale?
        PriceInfo.new(
          current: variant.price.format(symbol: "", with_currency: true, decimal_mark: " "),
          original: variant.compare_at_price.format(symbol: "", with_currency: true, decimal_mark: " "),
          discount_percentage: variant.discount_percentage,
          on_sale: true
        )
      else
        PriceInfo.new(
          current: variant.price.format(symbol: "", with_currency: true, decimal_mark: " "),
          original: nil,
          discount_percentage: nil,
          on_sale: false
        )
      end
    end

    def build_stock_info(variant)
      return StockInfo.new(available: false, message: "Out of stock", quantity: 0) unless variant

      if variant.in_stock?
        if variant.stock_quantity <= 5
          StockInfo.new(
            available: true,
            message: "Only #{variant.stock_quantity} left in stock",
            quantity: variant.stock_quantity
          )
        else
          StockInfo.new(
            available: true,
            message: "In stock",
            quantity: variant.stock_quantity
          )
        end
      else
        StockInfo.new(
          available: false,
          message: "Out of stock",
          quantity: 0
        )
      end
    end

    def build_color_options
      unique_colors.map do |color|
        VariantOption.new(
          name: color.humanize,
          value: color,
          available: color_available?(color),
          type: :color
        )
      end
    end

    def build_size_options
      unique_sizes.map do |variant|
        VariantOption.new(
          name: variant.size_value.to_s,
          value: build_size_key(variant),
          available: variant.in_stock?,
          type: variant.size_type&.to_sym || :size,
          variant_id: variant.id
        )
      end
    end

    def unique_colors
      @unique_colors ||= product.product_variants
                                .where.not(color: [ nil, "" ])
                                .distinct
                                .pluck(:color)
                                .compact
                                .uniq
    end

    def unique_sizes
      @unique_sizes ||= product.product_variants
                               .with_size
                               .to_a
                               .uniq { |variant| [ variant.size_value, variant.size_unit, variant.size_type ] }
                               .sort_by do |variant|
                                 type_order = case variant.size_type
                                 when "volume" then 1
                                 when "weight" then 2
                                 when "quantity" then 3
                                 else 4
                                 end
                                 [ type_order, variant.size_value || 0 ]
                               end
    end

    def color_available?(color)
      product.product_variants.where(color: color).any?(&:in_stock?)
    end

    def build_size_key(variant)
      return nil unless variant.has_size?
      "#{variant.size_value}:#{variant.size_unit}:#{variant.size_type}"
    end

    def build_product_images
      images = []

      if product.featured_image.attached?
        images << build_gallery_image(product.featured_image, :featured)
      end

      product.images.each_with_index do |image, index|
        next if product.featured_image.attached? && image == product.featured_image
        images << build_gallery_image(image, :gallery, nil, index + 2)
      end

      images
    end

    def build_gallery_image(attachment, type, variant = nil, index = 1)
      Products::GalleryImage.new(
        attachment: attachment,
        type: type,
        alt: build_alt_text(type, variant, index),
        variant_id: variant&.id
      )
    end

    def build_alt_text(type, variant, index)
      case type
      when :featured
        "#{product.name} - Main Image"
      when :variant
        "#{product.name} - #{variant.name}"
      when :gallery
        "#{product.name} - Image #{index}"
      else
        "#{product.name} - Product Image"
      end
    end
  end
end
