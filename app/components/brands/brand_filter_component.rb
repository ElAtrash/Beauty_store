# frozen_string_literal: true

class Brands::BrandFilterComponent < ViewComponent::Base
  delegate :name, to: :brand, prefix: true

  def initialize(brand:, total_products:)
    @brand = brand
    @total_products = total_products
  end

  private

  attr_reader :brand, :total_products

  def product_count_text
    @product_count_text ||= "#{total_products} #{'product'.pluralize(total_products)}"
  end

  def filter_options
    %w[price delivery\ time brand product\ type]
  end
end
