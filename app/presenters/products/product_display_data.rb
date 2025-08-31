# frozen_string_literal: true

module Products
  class ProductDisplayData
    attr_reader :product_info, :default_variant, :all_variants, :variant_images,
                :price_matrix, :stock_matrix, :variant_options

    def initialize(product_info:, default_variant:, all_variants:, variant_images:,
                   price_matrix:, stock_matrix:, variant_options:)
      @product_info = product_info
      @default_variant = default_variant
      @all_variants = all_variants
      @variant_images = variant_images
      @price_matrix = price_matrix
      @stock_matrix = stock_matrix
      @variant_options = variant_options
    end

    def price_info(variant_id = nil)
      price_data = variant_lookup_with_fallback(variant_id, price_matrix)
      return { current: "Price not available", on_sale: false } unless price_data

      price_data
    end

    def stock_info(variant_id = nil)
      stock_data = variant_lookup_with_fallback(variant_id, stock_matrix)
      return { available: false, message: "Out of stock", quantity: 0 } unless stock_data

      stock_data
    end

    def as_json(options = {})
      {
        default_variant: default_variant,
        all_variants: all_variants,
        variant_images: variant_images,
        price_matrix: price_matrix,
        stock_matrix: stock_matrix
      }
    end

    private

    def variant_lookup_with_fallback(variant_id, matrix)
      target_id = variant_id || default_variant[:id]
      matrix[target_id] || matrix[default_variant[:id]]
    end
  end

  ProductInfo = Struct.new(:name, :subtitle, :brand_name, :reviews_count, :rating, keyword_init: true)

  VariantOption = Struct.new(:name, :value, :available, :type, :variant_id, keyword_init: true) do
    def available?
      available
    end
  end
end
