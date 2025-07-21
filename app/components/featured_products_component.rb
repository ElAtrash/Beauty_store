# frozen_string_literal: true

class FeaturedProductsComponent < ViewComponent::Base
  def initialize(products:, pagy:)
    @products = products
    @pagy = pagy
  end

  private

  attr_reader :products, :pagy

  def has_more_products?
    pagy.next.present?
  end

  def next_page
    pagy.next
  end
end
