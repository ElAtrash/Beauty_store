class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product_variant

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :cart_id, uniqueness: { scope: :product_variant_id }

  def total_price
    product_variant.price * quantity
  end

  def product
    product_variant.product
  end
end
