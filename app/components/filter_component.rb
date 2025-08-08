# frozen_string_literal: true

class FilterComponent < ViewComponent::Base
  def initialize(filter_form:, products: nil, unfiltered_products: nil, context: nil, context_resource: nil, turbo_frame_id: nil)
    @filter_form = filter_form
    @products = products || Product.available
    @unfiltered_products = unfiltered_products || @products
    @context = context
    @context_resource = context_resource
    @turbo_frame_id = turbo_frame_id
  end

  private

  attr_reader :filter_form, :products, :unfiltered_products, :context, :context_resource, :turbo_frame_id

  def price_range
    @price_range ||= calculate_price_range
  end

  def skin_type_options
    @skin_type_options ||= begin
      return [] unless filter_form.filter_available?(:skin_types)

      available_skin_types = products.where("skin_types IS NOT NULL AND skin_types != '{}'")
                                    .pluck(:skin_types)
                                    .flatten
                                    .uniq
                                    .compact
                                    .sort

      available_skin_types.map { |type| { value: type, label: type.humanize } }
    end
  end

  def product_type_options
    @product_type_options ||= begin
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
  end

  def brand_options
    @brand_options ||= begin
      return [] unless filter_form.filter_available?(:brands)

      brand_ids = products.pluck(:brand_id).uniq.compact
      Brand.where(id: brand_ids)
           .order(:name)
           .pluck(:id, :name)
           .map { |id, name| { value: id, label: name } }
    end
  end

  def available_colors
    @available_colors ||= begin
      return [] unless filter_form.filter_available?(:colors)

      products.joins(:product_variants)
              .where.not(product_variants: { color: [ nil, "" ] })
              .distinct
              .pluck("product_variants.color")
              .compact
              .sort
              .map { |color| { value: color, label: color.humanize } }
    end
  end

  def available_sizes
    @available_sizes ||= begin
      return [] unless filter_form.filter_available?(:sizes)

      products.joins(:product_variants)
              .where.not(product_variants: { size: [ nil, "" ] })
              .distinct
              .pluck("product_variants.size")
              .compact
              .sort
              .map { |size| { value: size, label: size } }
    end
  end

  def filter_selected?(filter_type, value)
    filter_form.value_selected?(filter_type, value)
  end

  def in_stock_selected?
    filter_form.in_stock
  end

  def current_min_price
    filter_form.price_range_min || price_range[:min]
  end

  def current_max_price
    filter_form.price_range_max || price_range[:max]
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

  def controller_name
    case context
    when "brand"
      "filters--filter"
    when "product"
      "filters--filter"
    when "search"
      "filters--filter"
    else
      "filters--filter"
    end
  end

  def turbo_frame_target
    turbo_frame_id || "filtered_products"
  end
end
