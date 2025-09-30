# frozen_string_literal: true

class OrderConfirmation::ItemComponent < ViewComponent::Base
  include Rails.application.routes.url_helpers

  def initialize(order_item:)
    @order_item = order_item
  end

  private

  attr_reader :order_item

  delegate :product_name, :variant_name, :quantity, :unit_price, :total_price, to: :order_item

  def product
    order_item.product
  end

  def product_url
    product_path(product)
  end

  def featured_image
    order_item.product_variant.featured_image
  end

  def product_image
    if featured_image.attached?
      image_tag featured_image, alt: product_name, class: "w-full h-full object-cover"
    else
      content_tag :div, class: "w-full h-full flex items-center justify-center" do
        render UI::IconComponent.new(name: :photo, css_class: "w-4 h-4 text-gray-400", aria_hidden: true)
      end
    end
  end
end
