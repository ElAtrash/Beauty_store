# frozen_string_literal: true

class Cart::ModalWrapperComponent < ViewComponent::Base
  include Rails.application.routes.url_helpers

  def initialize(cart: nil)
    @cart = cart
  end

  private

  attr_reader :cart

  def empty_cart?
    cart.blank? || cart.total_quantity.to_i.zero?
  end

  def cart_title
    return I18n.t("cart.title") if empty_cart?

    "#{I18n.t('cart.title')} / #{format_units_text(cart_item_count)}"
  end

  def cart_item_count
    cart&.total_quantity.to_i
  end

  def cart_total_cents
    cart&.total_price&.cents || 0
  end

  def cart_currency
    cart&.total_price&.currency&.iso_code || "USD"
  end

  def cart_items
    cart&.ordered_items || []
  end

  def format_units_text(count)
    I18n.t("cart.units", count: count)
  end

  def clear_cart_button_classes
    class_names("flex", "items-center", "justify-center", "w-8", "h-8", "p-0")
  end

  def clear_cart_button_options
    {
      class: class_names("flex", "items-center", "justify-center", "w-8", "h-8", "p-0"),
      data: { turbo_method: "delete" },
      title: I18n.t("cart.clear_all.tooltip"),
      "aria-label": I18n.t("cart.clear_all.aria_label")
    }
  end
end
