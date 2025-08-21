# frozen_string_literal: true

module Filters
  class FilterOptionsService
    def initialize(products:, unfiltered_products:, filter_form:)
      @products = products
      @unfiltered_products = unfiltered_products
      @filter_form = filter_form
    end

    def skin_type_options
      @skin_type_options ||= build_skin_type_options
    end

    def product_type_options
      @product_type_options ||= build_product_type_options
    end

    def brand_options
      @brand_options ||= build_brand_options
    end

    def available_colors
      @available_colors ||= build_available_colors
    end

    def available_sizes
      @available_sizes ||= build_available_sizes
    end

    def price_range
      @price_range ||= calculate_price_range
    end

    private

    attr_reader :products, :unfiltered_products, :filter_form

    def build_skin_type_options
      return [] unless filter_form.filter_available?(:skin_types)

      available_skin_types = products.where("skin_types IS NOT NULL AND skin_types != '{}'")
                                    .pluck(:skin_types)
                                    .flatten
                                    .uniq
                                    .compact
                                    .sort

      available_skin_types.map { |type| { value: type, label: type.humanize } }
    end

    def build_product_type_options
      return [] unless filter_form.filter_available?(:product_types)

      category_ids = products.joins(:categories)
                            .where.not(categories: { parent_id: nil })
                            .pluck("categories.id")
                            .uniq

      Category.where(id: category_ids)
              .includes(:parent)
              .order(:name)
              .map { |cat| { value: cat.id, label: cat.name } }
    end

    def build_brand_options
      return [] unless filter_form.filter_available?(:brands)

      brand_ids = products.pluck(:brand_id).uniq.compact
      Brand.where(id: brand_ids)
           .order(:name)
           .pluck(:id, :name)
           .map { |id, name| { value: id, label: name } }
    end

    def build_available_colors
      return [] unless filter_form.filter_available?(:colors)

      products.joins(:product_variants)
              .where.not(product_variants: { color: [ nil, "" ] })
              .distinct
              .pluck("product_variants.color")
              .compact
              .sort
              .map { |color| { value: color, label: color.humanize } }
    end

    def build_available_sizes
      return [] unless filter_form.filter_available?(:sizes)

      # Get all unique size types from variants with size data
      size_types = products.joins(:product_variants)
                          .where.not(product_variants: { size_type: [ nil, "" ] })
                          .distinct
                          .pluck("product_variants.size_type")
                          .compact
                          .sort

      size_types.map { |size_type| { value: size_type, label: size_type.humanize } }
    end

    def calculate_price_range
      return { min: 0, max: 1000 } if unfiltered_products.empty?

      price_data = unfiltered_products.joins(:product_variants)
                                     .where.not(product_variants: { price_cents: nil })
                                     .pluck("MIN(product_variants.price_cents), MAX(product_variants.price_cents)")
                                     .first

      if price_data && price_data.compact.size == 2
        min_cents, max_cents = price_data
        {
          min: (min_cents / 100.0).floor,
          max: (max_cents / 100.0).ceil
        }
      else
        { min: 0, max: 1000 }
      end
    rescue StandardError => e
      Rails.logger.warn "Failed to calculate price range: #{e.message}"
      { min: 0, max: 1000 }
    end
  end
end
