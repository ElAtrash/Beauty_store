class CustomerProfile < ApplicationRecord
  belongs_to :user

  monetize :total_spent_cents, allow_nil: true

  enum skin_type: {
    oily: "oily",
    dry: "dry",
    combination: "combination",
    sensitive: "sensitive",
    normal: "normal"
  }

  enum skin_concerns: {
    acne: "acne",
    aging: "aging",
    dark_spots: "dark_spots",
    dullness: "dullness",
    sensitivity: "sensitivity",
    redness: "redness",
    pores: "pores"
  }, _multiple: true
end
