# frozen_string_literal: true

class Cart::FooterComponent < ViewComponent::Base
  include Rails.application.routes.url_helpers

  def initialize(total_price:)
    @total_price = total_price
  end

  private

  attr_reader :total_price

  def container_classes
    class_names("space-y-4")
  end

  def order_summary_classes
    class_names("pt-4")
  end

  def order_title_classes
    class_names("text-lg", "font-medium", "text-gray-900", "mb-4")
  end

  def cost_row_classes
    class_names("flex", "items-center", "justify-between", "mb-3")
  end

  def cost_label_classes
    class_names("text-sm", "text-gray-700")
  end

  def dotted_line_classes
    class_names("flex-1", "mx-3", "border-b", "border-dotted", "border-gray-300")
  end

  def cost_value_classes
    class_names("text-sm", "font-medium", "text-gray-900")
  end

  def total_row_classes
    class_names("flex", "items-center", "justify-between", "pt-3")
  end

  def total_label_classes
    class_names("text-base", "font-medium", "text-gray-900")
  end

  def total_value_classes
    class_names("text-xl", "font-bold", "text-gray-900")
  end

  def checkout_button_classes
    class_names("btn-interactive", "btn-full", "btn-lg")
  end

  def checkout_content_classes
    class_names("flex", "items-center", "justify-center", "gap-2")
  end

  def checkout_data_attributes
    { turbo_frame: "_top" }
  end
end
