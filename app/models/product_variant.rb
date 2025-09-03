class ProductVariant < ApplicationRecord
  belongs_to :product

  has_many_attached :images
  has_one_attached :featured_image
  has_many :cart_items, dependent: :destroy
  has_many :wishlists, dependent: :destroy

  monetize :price_cents
  monetize :compare_at_price_cents, allow_nil: true
  monetize :cost_cents, allow_nil: true

  validates :name, :sku, :price_cents, :stock_quantity,
            :conversion_score, :sales_count, presence: true

  validates :sku, uniqueness: true
  validates :price_cents, numericality: { greater_than: 0 }
  validates :stock_quantity, :conversion_score, :sales_count,
            numericality: { greater_than_or_equal_to: 0 }

  validates :color_hex, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }, allow_blank: true

  after_commit :warm_product_cache_later, on: %i[create update destroy]

  scope :in_stock, -> { where("stock_quantity > 0") }
  scope :available, -> { joins(:product).merge(Product.available) }
  scope :ordered, -> { order(:position) }
  scope :with_size, -> { where.not(size_value: nil) }
  scope :with_color, -> { where.not(color_hex: [ nil, "" ]) }
  scope :ordered_by_size, -> {
    with_size.order(
      Arel.sql("CASE size_type WHEN 'volume' THEN 1 WHEN 'weight' THEN 2 WHEN 'quantity' THEN 3 ELSE 4 END"),
      :size_value,
      :id
    )
  }

  scope :marked_default, -> { where(is_default: true) }
  scope :canonical, -> { where(canonical_variant: true) }
  scope :by_sales_count, -> { order(sales_count: :desc) }
  scope :ordered_by_price, -> { order(:price_cents) }
  scope :with_performance, -> { where("sales_count > 0 OR conversion_score > 0") }
  scope :bestseller, -> { where("sales_count >= ? AND conversion_score >= ?", 20, 5.0) }
  scope :performing, -> { where("sales_count > ? OR conversion_score > ?", 0, 0) }

  # Find variant by size key string (e.g., "50:ml:volume")
  scope :by_size_key, ->(size_key_string) {
    return none if size_key_string.blank?

    parts = size_key_string.split(":")
    return none if parts.length != 3

    size_value, size_unit, size_type = parts
    where(
      size_value: size_value.to_f,
      size_unit: size_unit,
      size_type: size_type
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
    compare_at_price&.positive? && compare_at_price > price
  end

  def discount_amount
    return Money.new(0) unless on_sale?

    compare_at_price - price
  end

  def discount_percentage
    return 0 unless on_sale?

    calculate_discount_percentage
  end

  def size?
    size_value.present?
  end

  def color?
    color_hex.present?
  end

  def formatted_size_value
    return nil unless size_value.present?

    size_value.to_i == size_value.to_f ? size_value.to_i.to_s : size_value.to_s
  end

  def size_key
    return nil unless size?

    [ formatted_size_value, size_unit, size_type ].compact.join(":")
  end

  private

  def calculate_discount_percentage
    ((discount_amount / compare_at_price) * 100).round
  end

  def warm_product_cache_later
    Products::ProductCacheWarmerJob.perform_later(product_id)
  end
end
