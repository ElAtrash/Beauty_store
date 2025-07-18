class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :product_variant

  monetize :unit_price_cents
  monetize :total_price_cents

  validates :product_name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price_cents, presence: true, numericality: { greater_than: 0 }
  validates :total_price_cents, presence: true, numericality: { greater_than: 0 }

  before_validation :set_product_details, on: :create
  before_validation :calculate_total_price

  private

  def set_product_details
    return unless product_variant

    self.product = product_variant.product
    self.product_name = product_variant.product.name
    self.variant_name = product_variant.name
    self.unit_price = product_variant.price
  end

  def calculate_total_price
    return unless unit_price && quantity

    self.total_price = unit_price * quantity
  end
end
