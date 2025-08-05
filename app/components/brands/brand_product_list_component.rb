# frozen_string_literal: true

class Brands::BrandProductListComponent < ViewComponent::Base
  delegate :name, to: :brand, prefix: true
  delegate :count, to: :pagy, prefix: :total_products
  delegate :next, to: :pagy, prefix: :next_page

  def initialize(brand:, products:, pagy:)
    @brand = brand
    @products = products
    @pagy = pagy
  end

  private

  attr_reader :brand, :products, :pagy

  def products?
    @products_present ||= products.present?
  end

  def more_products?
    @more_products ||= pagy.next.present?
  end
end
