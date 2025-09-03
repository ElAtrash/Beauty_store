# frozen_string_literal: true

module StockStatus
  extend ActiveSupport::Concern

  included do
    scope :in_stock, -> {
      joins(:product_variants)
        .merge(ProductVariant.in_stock)
        .distinct
    }
  end

  def all_variants_out_of_stock?
    !any_variants_in_stock?
  end

  def any_variants_in_stock?
    return @any_variants_in_stock if defined?(@any_variants_in_stock)

    @any_variants_in_stock =
      if product_variants.loaded?
        product_variants.any?(&:in_stock?)
      else
        product_variants.in_stock.exists?
      end
  end

  def size_only_variants?
    return @size_only_variants if defined?(@size_only_variants)

    if product_variants.loaded?
      @size_only_variants = check_variants_loaded(product_variants.to_a) { |v| v.size? && !v.color? }
    else
      @size_only_variants = product_variants.with_size.exists? && !product_variants.with_color.exists?
    end
  end

  def has_color_variants?
    return @has_color_variants if defined?(@has_color_variants)

    if product_variants.loaded?
      @has_color_variants = check_variants_loaded(product_variants.to_a, &:color?)
    else
      @has_color_variants = product_variants.with_color.exists?
    end
  end

  private

  def check_variants_loaded(variants)
    return false if variants.empty?
    variants.any? { |variant| yield(variant) }
  end
end
