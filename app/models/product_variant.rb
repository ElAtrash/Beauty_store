class ProductVariant < ApplicationRecord
  belongs_to :product

  has_many_attached :images
  has_one_attached :featured_image
  has_many :cart_items, dependent: :destroy
  has_many :wishlists, dependent: :destroy

  monetize :price_cents
  monetize :compare_at_price_cents, allow_nil: true
  monetize :cost_cents, allow_nil: true

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :stock_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :in_stock, -> { where("stock_quantity > 0") }
  scope :available, -> { joins(:product).merge(Product.available) }
  scope :ordered, -> { order(:position) }
  scope :with_size, -> { where.not(size_value: nil) }
  scope :ordered_by_size, -> {
    with_size.order(
      Arel.sql("CASE size_type WHEN 'volume' THEN 1 WHEN 'weight' THEN 2 WHEN 'quantity' THEN 3 ELSE 4 END"),
      :size_value,
      :id
    )
  }

  def in_stock?
    return true unless track_inventory?

    stock_quantity > 0 || allow_backorder?
  end

  def available?
    product.available? && in_stock?
  end

  def on_sale?
    compare_at_price.present? && compare_at_price > Money.new(0) && compare_at_price > price
  end

  def discount_amount
    return Money.new(0) unless on_sale?

    compare_at_price - price
  end

  def discount_percentage
    return 0 unless on_sale?

    calculate_discount_percentage
  end

  def compare_at_price_difference
    "#{discount_percentage}% off"
  end

  def display_name
    "#{product.name} - #{name}"
  end

  def has_size?
    size_value.present?
  end

  def size_display
    return nil unless has_size?

    case size_type
    when "volume"
      "#{size_value} #{size_unit}"
    when "weight"
      "#{size_value} #{size_unit}"
    when "quantity"
      size_value == 1 ? "#{size_value} piece" : "#{size_value} pieces"
    else
      "#{size_value} #{size_unit}"
    end
  end

  def size_display_short
    return nil unless has_size?

    case size_type
    when "volume"
      "#{size_value}#{size_unit}"
    when "weight"
      "#{size_value}#{size_unit}"
    when "quantity"
      size_value == 1 ? "#{size_value}pc" : "#{size_value}pcs"
    else
      "#{size_value}#{size_unit}"
    end
  end

  private

  def calculate_discount_percentage
    ((discount_amount / compare_at_price) * 100).round
  end
end
