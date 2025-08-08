# frozen_string_literal: true

class BrandSectionComponent < ViewComponent::Base
  def initialize(letter:, brands:)
    @letter = letter
    @brands = brands
  end

  private

  attr_reader :letter, :brands

  def section_id
    @section_id ||= "section-#{letter.downcase}"
  end

  def brand_path(brand)
    Rails.application.routes.url_helpers.brand_path(brand)
  end

  def brand_products_count(brand)
    brand.products_count || 0
  end

  def pluralize_products(count)
    count == 1 ? "product" : "products"
  end

  def brands_count
    @brands_count ||= brands.count
  end

  def brands_count_text
    @brands_count_text ||= "#{brands_count} #{brands_count == 1 ? 'brand' : 'brands'}"
  end
end
