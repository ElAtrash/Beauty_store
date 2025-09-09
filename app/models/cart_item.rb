class CartItem < ApplicationRecord
  DEFAULT_CURRENCY = "USD"

  belongs_to :cart
  belongs_to :product_variant

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :cart_id, uniqueness: { scope: :product_variant_id }
  validates :price_snapshot_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :price_snapshot_currency, presence: true, format: { with: /\A[A-Z]{3}\z/, message: "must be a 3-letter ISO currency code" }

  before_validation :set_price_snapshot, on: :create

  def total_price
    Money.new(price_snapshot_cents, price_snapshot_currency || DEFAULT_CURRENCY) * quantity
  end

  def unit_price
    Money.new(price_snapshot_cents, price_snapshot_currency || DEFAULT_CURRENCY)
  end

  def total_price_cents
    price_snapshot_cents * quantity
  end

  def product
    product_variant.product
  end

  private

  def set_price_snapshot
    if product_variant&.price
      self.price_snapshot_cents = product_variant.price.cents
      self.price_snapshot_currency = product_variant.price.currency.iso_code
    else
      self.price_snapshot_cents ||= 0
      self.price_snapshot_currency ||= DEFAULT_CURRENCY
    end
  end
end
