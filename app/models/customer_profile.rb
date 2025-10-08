class CustomerProfile < ApplicationRecord
  belongs_to :user

  monetize :total_spent_cents, allow_nil: true

  # DEPRECATED: default_delivery_address JSONB field
  # Use user.addresses (Address model) instead
  # This field will be removed in a future migration
  # store_accessor :default_delivery_address (commented out for migration)

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

  # DEPRECATED METHODS - Will be removed after full migration to Address model
  # def has_default_address?
  #   Rails.logger.warn "[DEPRECATED] CustomerProfile#has_default_address? - Use user.addresses instead"
  #   default_delivery_address.present? && default_delivery_address["address_line_1"].present?
  # end

  # def save_delivery_address_from_order(order, label: "Home")
  #   Rails.logger.warn "[DEPRECATED] CustomerProfile#save_delivery_address_from_order - Use user.addresses.create! instead"
  #   update!(...)
  # end
end
