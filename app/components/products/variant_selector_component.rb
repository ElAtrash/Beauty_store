# frozen_string_literal: true

module Products
  class VariantSelectorComponent < ViewComponent::Base
    def initialize(product:, variant_options:, stock_info:, product_data:)
      @product = product
      @variant_options = (variant_options || {}).reverse_merge(sizes: [], colors: [])
      @stock_info = stock_info
      @product_data = product_data
      @selected_variant = extract_selected_variant_from_product_data
    end

    private

    attr_reader :product, :variant_options, :stock_info, :product_data, :selected_variant


    def has_sizes?
      product.product_variants.any?(&:size?)
    end

    def has_colors? = variant_options[:colors].any?

    def size_type_label
      case variant_options[:sizes].first&.type&.to_sym
      when :volume then "VOLUME / ML"
      when :weight then "WEIGHT / G"
      else "SIZE"
      end
    end

    def first_color_option
      preferred = selected_variant&.color_hex || product.default_variant&.color_hex
      default_option(variant_options[:colors], preferred)
    end

    def default_size_option
      return nil unless selected_variant&.size? || product.default_variant&.size?

      preferred = selected_variant&.size_key || product.default_variant&.size_key
      default_option(variant_options[:sizes], preferred)
    end

    def variant_available?(variant_id)
      product_data.variant_available?(variant_id)
    end

    private

    def extract_selected_variant_from_product_data
      # The selected variant is stored in default_variant from the dynamic data
      return unless product_data.respond_to?(:default_variant)

      variant_data = product_data.default_variant
      return unless variant_data && variant_data[:id]

      product.product_variants.find_by(id: variant_data[:id])
    rescue => e
      Rails.logger.debug "Could not extract selected variant from product_data: #{e.message}"
      nil
    end

    def default_option(options, preferred_value)
      options.find { |opt| opt.value == preferred_value } || options.first
    end
  end
end
