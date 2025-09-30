# frozen_string_literal: true

class OrderConfirmation::ContactComponent < ViewComponent::Base
  def initialize(order:)
    @order = order
  end

  private

  attr_reader :order

  def delivery_method_label
    key = order.courier? ? :courier : :pickup
    I18n.t("order.contact.delivery_methods.#{key}")
  end

  def shipping_address
    order.shipping_address || {}
  end

  def address_line_1
    shipping_address["address_line_1"]
  end

  def address_line_2
    shipping_address["address_line_2"]
  end

  def landmarks
    shipping_address["landmarks"]
  end

  def show_delivery_address?
    order.courier?
  end

  def show_delivery_notes?
    order.courier? && order.delivery_notes.present?
  end

  def detail_row(label_key, value)
    content_tag :div do
      concat content_tag(:p, t(label_key), class: "text-sm font-medium text-text-secondary")
      concat content_tag(:p, value, class: "text-sm text-text-primary")
    end
  end

  def detail_row_with_content(label_key, &block)
    content_tag :div do
      concat content_tag(:p, t(label_key), class: "text-sm font-medium text-text-secondary")
      concat content_tag(:div, class: "text-sm text-text-primary", &block)
    end
  end
end
