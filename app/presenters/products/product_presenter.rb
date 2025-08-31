# frozen_string_literal: true

module Products
  class ProductPresenter
    def initialize(product, selected_variant: nil)
      @product = product
      @selected_variant = selected_variant || product.default_variant
      @variants = product.product_variants.includes(
        featured_image_attachment: :blob,
        images_attachments: :blob
      ).to_a
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

    attr_reader :product, :selected_variant, :variants

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
        name: variant.name || "",
        color: variant.color || "",
        color_hex: variant.color_hex || "",
        size_value: variant.size_value,
        size_unit: variant.size_unit || "",
        size_type: variant.size_type || "",
        size_key: variant.size_key,
        sku: variant.sku || ""
      }
    end

    def build_all_variants_data
      @all_variants_data ||= variants.map do |variant|
        build_variant_data(variant)
      end
    end

    def build_variant_images_mapping
      @variant_images_mapping ||= begin
        mapping = {}

        variants.each do |variant|
          variant_images = build_variant_specific_images(variant)
          mapping[variant.id] = variant_images.map(&:as_json)
        end

        mapping
      end
    end

    def build_price_matrix
      @price_matrix ||= variants.each_with_object({}) do |variant, matrix|
        price_info = build_price_info(variant)
        matrix[variant.id] = price_info
      end
    end

    def build_stock_matrix
      @stock_matrix ||= variants.each_with_object({}) do |variant, matrix|
        stock_info = build_stock_info(variant)
        matrix[variant.id] = {
          available: stock_info[:available],
          message: stock_info[:message],
          quantity: stock_info[:quantity]
        }
      end
    end

    def build_variant_options
      @variant_options ||= {
        colors: build_color_options,
        sizes: build_size_options
      }
    end

    def build_price_info(variant)
      return {
        current_cents: nil,
        currency: "USD",
        on_sale: false,
        formatted_current_price: "Price unavailable",
        formatted_original_price: nil
      } unless variant

      if variant.on_sale?
        {
          current_cents: variant.price.cents,
          original_cents: variant.compare_at_price.cents,
          currency: variant.price.currency.iso_code,
          discount_percentage: variant.discount_percentage,
          on_sale: true,
          formatted_current_price: variant.price.format(symbol: "", with_currency: true, decimal_mark: " "),
          formatted_original_price: variant.compare_at_price.format(symbol: "", with_currency: true, decimal_mark: " ")
        }
      else
        {
          current_cents: variant.price.cents,
          original_cents: nil,
          currency: variant.price.currency.iso_code,
          discount_percentage: nil,
          on_sale: false,
          formatted_current_price: variant.price.format(symbol: "", with_currency: true, decimal_mark: " "),
          formatted_original_price: nil
        }
      end
    end

    def build_stock_info(variant)
      return { available: false, message: I18n.t("products.stock.out_of_stock"), quantity: 0 } unless variant

      if variant.in_stock?
        if variant.stock_quantity <= 5
          {
            available: true,
            message: I18n.t("products.stock.low_stock", count: variant.stock_quantity),
            quantity: variant.stock_quantity
          }
        else
          {
            available: true,
            message: I18n.t("products.stock.in_stock"),
            quantity: variant.stock_quantity
          }
        end
      else
        {
          available: false,
          message: I18n.t("products.stock.out_of_stock"),
          quantity: 0
        }
      end
    end

    def build_color_options
      unique_color_variants.map do |variant|
        Products::VariantOption.new(
          name: variant.color,
          value: variant.color_hex,
          available: variant.in_stock?,
          type: :color
        )
      end
    end

    def build_size_options
      unique_sizes.map do |variant|
        Products::VariantOption.new(
          name: variant.formatted_size_value || variant.size_value.to_s,
          value: variant.size_key,
          available: variant.in_stock?,
          type: variant.size_type&.to_sym || :size,
          variant_id: variant.id
        )
      end
    end

    def unique_color_variants
      @unique_color_variants ||= variants
                                  .select { |v| v.color_hex.present? }
                                  .uniq { |v| v.color_hex }
    end

    def unique_sizes
      @unique_sizes ||= begin
        size_variants = variants.select(&:has_size?)
        return [] if size_variants.empty?

        unique_variants = size_variants.uniq { |variant| [ variant.size_value, variant.size_unit, variant.size_type ] }

        final_variants = unique_variants.empty? ? [ size_variants.first ] : unique_variants

        final_variants.sort_by do |variant|
          type_order = case variant.size_type
          when "volume" then 1
          when "weight" then 2
          when "quantity" then 3
          else 4
          end
          [ type_order, variant.size_value || 0 ]
        end
      end
    end

    def color_available?(color_hex)
      variants.any? { |variant| variant.color_hex == color_hex && variant.in_stock? }
    end

    def build_variant_specific_images(variant)
      images = []

      if variant.featured_image.attached?
        images << build_gallery_image(variant.featured_image, :variant, variant, 1)
      end

      if variant.images.attached?
        variant.images.each_with_index do |image, index|
          next if variant.featured_image.attached? && image == variant.featured_image
          images << build_gallery_image(image, :variant, variant, index + 2)
        end
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
