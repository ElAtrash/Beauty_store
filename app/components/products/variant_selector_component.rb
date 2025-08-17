# frozen_string_literal: true

module Products
  class VariantSelectorComponent < ViewComponent::Base
    def initialize(product:, variant_options:, stock_info:)
      @product = product
      @variant_options = variant_options
      @stock_info = stock_info
    end

    private

    attr_reader :product, :variant_options, :stock_info

    def has_sizes?
      variant_options[:sizes].any?
    end

    def has_colors?
      variant_options[:colors].any?
    end

    def size_type_label
      return "SIZE" unless has_sizes?

      case variant_options[:sizes].first.type
      when :volume
        "VOLUME / ML"
      when :weight
        "WEIGHT / G"
      else
        "SIZE"
      end
    end

    def first_color_option
      if product.default_variant&.color.present?
        variant_options[:colors].find { |opt| opt.value == product.default_variant.color }
      end || variant_options[:colors].first
    end
  end
end
