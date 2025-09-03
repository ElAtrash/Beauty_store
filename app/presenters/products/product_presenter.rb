# frozen_string_literal: true

module Products
  class ProductPresenter
    attr_reader :product, :variants

    def initialize(product)
      @product = product
      @variants = product.product_variants.includes(
        featured_image_attachment: :blob,
        images_attachments: :blob
      ).to_a
    end

    def build_static_data
      ProductDisplayData.new(
        product_info: build_product_info,
        all_variants: build_all_variants_data,
        variant_images: build_variant_images_mapping
      )
    end

    def build_dynamic_data(selected_variant:)
      ProductDisplayData.new(
        default_variant: build_variant_data(selected_variant),
        price_matrix: build_price_matrix,
        stock_matrix: build_stock_matrix,
        variant_options: build_variant_options
      )
    end

    private

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
      @all_variants_data ||= variants.map { |v| build_variant_data(v) }
    end

    def build_variant_images_mapping
      @variant_images_mapping ||= variants.each_with_object({}) do |variant, mapping|
        images = []
        images << build_gallery_image(variant.featured_image, :variant, variant, 1) if variant.featured_image.attached?
        if variant.images.attached?
          variant.images.each_with_index do |img, idx|
            next if variant.featured_image.attached? && img == variant.featured_image
            images << build_gallery_image(img, :variant, variant, idx + 2)
          end
        end
        mapping[variant.id] = images.map(&:as_json)
      end
    end

    def build_gallery_image(attachment, type, variant = nil, index = 1)
      Products::GalleryImage.new(
        attachment: attachment,
        type: type,
        alt: "#{product.name} - #{variant&.name || "Image #{index}"}",
        variant_id: variant&.id
      )
    end

    def build_price_matrix
      variants.each_with_object({}) { |v, h| h[v.id] = build_price_info(v) }
    end

    def build_stock_matrix
      variants.each_with_object({}) { |v, h| h[v.id] = build_stock_info(v) }
    end

    def build_variant_options(selected_variant = nil)
      {
        colors: unique_color_variants.map { |v| VariantOption.new(name: v.color, value: v.color_hex, available: v.in_stock?, type: :color) },
        sizes: unique_sizes.map { |v| VariantOption.new(name: v.formatted_size_value || v.size_value.to_s, value: v.size_key, available: v.in_stock?, type: v.size_type&.to_sym || :size, variant_id: v.id) }
      }
    end

    def unique_color_variants
      @unique_color_variants ||= variants.select(&:color?).uniq { |v| v.color_hex }
    end

    def unique_sizes
      @unique_sizes ||= begin
        size_variants = variants.select(&:size?)
        return [] if size_variants.empty?
        size_variants.uniq { |v| [ v.size_value, v.size_unit, v.size_type ] }
                     .sort_by { |v| [ %w[volume weight quantity].index(v.size_type) || 4, v.size_value || 0 ] }
      end
    end

    def build_price_info(v)
      return { current_cents: nil, currency: "USD", on_sale: false, formatted_current_price: "Price unavailable" } unless v

      if v.on_sale?
        {
          current_cents: v.price.cents,
          original_cents: v.compare_at_price.cents,
          currency: v.price.currency.iso_code,
          discount_percentage: v.discount_percentage,
          on_sale: true,
          formatted_current_price: v.price.format(symbol: "", with_currency: true, decimal_mark: " "),
          formatted_original_price: v.compare_at_price.format(symbol: "", with_currency: true, decimal_mark: " ")
        }
      else
        {
          current_cents: v.price.cents,
          original_cents: nil,
          currency: v.price.currency.iso_code,
          discount_percentage: nil,
          on_sale: false,
          formatted_current_price: v.price.format(symbol: "", with_currency: true, decimal_mark: " "),
          formatted_original_price: nil
        }
      end
    end

    def build_stock_info(v)
      if v.in_stock?
        msg = v.stock_quantity <= 5 ? I18n.t("products.stock.low_stock", count: v.stock_quantity) : I18n.t("products.stock.in_stock")
        { available: true, message: msg, quantity: v.stock_quantity }
      else
        { available: false, message: I18n.t("products.stock.out_of_stock"), quantity: 0 }
      end
    end
  end
end
