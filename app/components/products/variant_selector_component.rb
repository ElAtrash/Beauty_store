# frozen_string_literal: true

module Products
  class VariantSelectorComponent < ViewComponent::Base
    def initialize(product:, variant_options:, stock_info:, product_data:)
      @product = product
      @variant_options = (variant_options || {}).reverse_merge(sizes: [], colors: [])
      @stock_info = stock_info
      @product_data = product_data
    end

    private

    attr_reader :product, :variant_options, :stock_info, :product_data

    def product_data_json
      data_hash = product_data.as_json
      json_string = data_hash.to_json

      json_string.html_safe
    rescue JSON::GeneratorError, NoMethodError => e
      Rails.logger.error "Error generating product_data_json: #{e.message}"
      Rails.logger.error "ProductData: #{product_data.inspect}"
      "{}".html_safe
    end

    def has_sizes?
      product.product_variants.any?(&:has_size?)
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
      preferred = product.default_variant&.color_hex
      default_option(variant_options[:colors], preferred)
    end

    def default_size_option
      return nil unless product.default_variant&.has_size?

      preferred = product.default_variant.size_key
      default_option(variant_options[:sizes], preferred)
    end

    private

    def default_option(options, preferred_value)
      options.find { |opt| opt.value == preferred_value } || options.first
    end
  end
end
