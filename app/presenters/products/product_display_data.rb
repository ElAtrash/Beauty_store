# frozen_string_literal: true

module Products
  ProductDisplayData = Struct.new(
    :product_info,
    :default_variant,
    :all_variants,
    :variant_images,
    :price_matrix,
    :stock_matrix,
    :variant_options,
    keyword_init: true
  ) do
    # Get variant data by ID (for future dynamic selection)
    def variant_by_id(variant_id)
      return default_variant if variant_id.nil?
      all_variants.find { |v| v[:id] == variant_id.to_i } || default_variant
    end

    # Get images for a specific variant (for gallery updates)
    def images_for_variant(variant_id = nil)
      target_id = variant_id || default_variant[:id]
      variant_images[target_id] || variant_images[default_variant[:id]] || []
    end

    # Get price info for a specific variant
    def price_for_variant(variant_id = nil)
      target_id = variant_id || default_variant[:id]
      price_matrix[target_id] || price_matrix[default_variant[:id]]
    end

    # Get stock info for a specific variant
    def stock_for_variant(variant_id = nil)
      target_id = variant_id || default_variant[:id]
      stock_matrix[target_id] || stock_matrix[default_variant[:id]]
    end

    # Check if product has multiple variants (for UI decisions)
    def has_variants?
      all_variants.size > 1
    end

    # Get all variant data as JSON for JavaScript consumption
    def to_js_data
      {
        defaultVariant: default_variant,
        allVariants: all_variants,
        variantImages: variant_images,
        priceMatrix: price_matrix,
        stockMatrix: stock_matrix
      }
    end
  end

  # Product basic information struct
  ProductInfo = Struct.new(:name, :subtitle, :brand_name, :reviews_count, :rating, keyword_init: true)

  # Price display information
  PriceInfo = Struct.new(:current, :original, :discount_percentage, :on_sale, keyword_init: true) do
    def on_sale?
      on_sale
    end
  end

  # Stock status information
  StockInfo = Struct.new(:available, :message, :quantity, keyword_init: true) do
    def available?
      available
    end

    def low_stock?
      available? && quantity && quantity <= 5
    end
  end

  # Variant option for UI forms
  VariantOption = Struct.new(:name, :value, :available, :type, :variant_id, keyword_init: true) do
    def available?
      available
    end
  end
end
