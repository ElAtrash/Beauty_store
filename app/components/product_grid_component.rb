# frozen_string_literal: true

class ProductGridComponent < ViewComponent::Base
  def initialize(products:, wrapper_classes: nil)
    @products = products
    @wrapper_classes = wrapper_classes
  end

  private

  attr_reader :products, :wrapper_classes

  def products?
    @products_present ||= products.present?
  end

  def grid_wrapper_classes
    wrapper_classes || "data-product-grid-target=\"product\""
  end
end
