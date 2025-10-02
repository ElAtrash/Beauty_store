class CustomerProfile < ApplicationRecord
  DEFAULT_ADDRESS_LABEL = "Home"

  belongs_to :user

  monetize :total_spent_cents, allow_nil: true

  store_accessor :default_delivery_address,
    :address_line_1,
    :address_line_2,
    :city,
    :governorate,
    :landmarks,
    :phone_number,
    :label,
    :last_used_at

  enum :skin_type, {
    oily: "oily",
    dry: "dry",
    combination: "combination",
    sensitive: "sensitive",
    normal: "normal"
  }

  enum :skin_concerns, {
    acne: "acne",
    aging: "aging",
    dark_spots: "dark_spots",
    dullness: "dullness",
    sensitivity: "sensitivity",
    redness: "redness",
    pores: "pores"
  }, _multiple: true

  def has_default_address?
    default_delivery_address.present? &&
    default_delivery_address["address_line_1"].present?
  end

  def save_delivery_address_from_order(order, label: DEFAULT_ADDRESS_LABEL)
    update!(
      default_delivery_address: {
        address_line_1: order.shipping_address["address_line_1"],
        address_line_2: order.shipping_address["address_line_2"],
        city: order.shipping_address["city"],
        governorate: order.shipping_address["governorate"],
        landmarks: order.shipping_address["landmarks"],
        phone_number: order.phone_number,
        label: label,
        last_used_at: Date.current
      }
    )
  end
end
