# frozen_string_literal: true

class Cart::ContentComponent < ViewComponent::Base
  def initialize(cart_items:, modal_controller: "modal")
    @cart_items = cart_items
    @modal_controller = modal_controller
  end

  private

  attr_reader :cart_items, :modal_controller

  def empty_cart?
    cart_items.empty?
  end

  def empty_container_classes
    class_names("text-center", "py-12")
  end

  def empty_icon_container_classes
    class_names("mb-6", "flex", "items-center", "justify-center")
  end

  def empty_title_classes
    class_names("text-lg", "font-medium", "text-gray-900", "mb-2")
  end

  def empty_description_classes
    class_names("text-gray-600", "mb-6")
  end

  def empty_button_classes
    class_names("btn-interactive", "btn-lg")
  end

  def empty_button_data_attributes
    { action: "click->#{modal_controller}#close" }
  end

  def items_container_classes
    class_names()
  end

  def item_wrapper_classes(is_last_item)
    class_names(("border-b border-gray-100" unless is_last_item))
  end
end
