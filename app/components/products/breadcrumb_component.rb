# frozen_string_literal: true

class Products::BreadcrumbComponent < ViewComponent::Base
  def initialize(breadcrumbs:, product_name:)
    @breadcrumbs = breadcrumbs
    @product_name = product_name
  end

  private

  attr_reader :breadcrumbs, :product_name
end
