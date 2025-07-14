class Wishlist < ApplicationRecord
  belongs_to :user
  belongs_to :product_variant

  validates :user_id, uniqueness: { scope: :product_variant_id }

  def product
    product_variant.product
  end
end
