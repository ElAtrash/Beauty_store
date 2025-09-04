class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  include StockStatus

  belongs_to :brand, optional: true, counter_cache: true

  has_many :product_variants, dependent: :destroy
  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :collection_products, dependent: :destroy
  has_many :collections, through: :collection_products
  has_many :reviews, dependent: :destroy
  has_many :order_items, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  SKIN_TYPES = %w[oily dry combination sensitive normal].freeze
  HAIR_TYPES = %w[straight wavy curly coily fine thick damaged colored].freeze

  validates :skin_types, inclusion: { in: SKIN_TYPES }, allow_blank: true
  validates :product_attributes, presence: true

  after_commit :warm_cache_later, on: %i[create update]

  store_accessor :product_attributes,
    :hair_type, :sulfate_free, :paraben_free, :color_safe, :texture,
    :finish, :water_resistant, :skin_type, :spf, :alcohol_free,
    :fragrance_family, :longevity, :sillage, :material, :intended_for,
    :application_area, :suitable_for, :cruelty_free

  scope :available, -> { where(active: true).where("published_at IS NOT NULL AND published_at <= ?", Time.current) }

  def self.find_available!(slug)
    available.friendly.find(slug)
  end

  scope :by_brand, ->(brand_ids) {
    ids = normalize_ids(brand_ids)
    where(brand_id: ids) if ids.any?
  }
  scope :by_price_range, ->(min, max) {
    return all unless min.present? || max.present?
    rel = joins(:product_variants)
    rel = rel.where("product_variants.price_cents >= ?", (min.to_f * 100).to_i) if min
    rel = rel.where("product_variants.price_cents <= ?", (max.to_f * 100).to_i) if max
    rel.distinct
  }
  scope :by_categories, ->(category_ids) {
    ids = normalize_ids(category_ids)
    joins(:categories).where(categories: { id: ids }).distinct if ids.any?
  }
  scope :by_skin_types, ->(types) {
    valid = normalize_ids(types) & SKIN_TYPES
    where("skin_types && ARRAY[?]::varchar[]", valid) if valid.any?
  }
  scope :by_colors, ->(colors) {
    valid_colors = normalize_ids(colors)
    joins(:product_variants).where(product_variants: { color: valid_colors }).distinct if valid_colors.any?
  }
  scope :by_sizes, ->(sizes) {
    valid_sizes = normalize_ids(sizes)
    joins(:product_variants).where(product_variants: { size_type: valid_sizes }).distinct if valid_sizes.any?
  }

  scope :by_attribute, ->(key, values) {
    vals = normalize_ids(values)
    where("product_attributes ->> ? = ANY(?)", key, vals) if vals.any?
  }

  scope :by_popularity, -> {
    with_stock_priority.left_joins(:reviews)
      .order(Arel.sql("COUNT(reviews.id) DESC"), :name)
  }

  scope :by_price, ->(direction = :asc) {
    dir = direction.to_s.downcase == "desc" ? "DESC" : "ASC"

    with_stock_priority.joins(:product_variants)
      .order(Arel.sql("MIN(product_variants.price_cents) #{dir}"))
  }

  scope :by_rating, -> {
    with_stock_priority.left_joins(:reviews)
      .order(Arel.sql("AVG(COALESCE(reviews.rating, 0)) DESC"), :name)
  }

  scope :by_best_sellers, -> {
    with_stock_priority.left_joins(:order_items)
      .order(Arel.sql("SUM(COALESCE(order_items.quantity, 0)) DESC"), :name)
  }

  scope :sorted, ->(sort_option) {
    case sort_option&.to_s
    when "popularity" then by_popularity
    when "price_asc" then by_price(:asc)
    when "price_desc" then by_price(:desc)
    when "rating" then by_rating
    when "best_sellers" then by_best_sellers
    else by_popularity
    end
  }

  scope :filtered, ->(filters = {}) {
    rel = all
    rel = rel.in_stock if filters[:in_stock].to_s == "true"
    rel = rel.by_brand(filters[:brands])
    rel = rel.by_price_range(filters.dig(:price_range, :min), filters.dig(:price_range, :max))
    rel = rel.by_categories(filters[:product_types])
    rel = rel.by_skin_types(filters[:skin_types])
    rel = rel.by_colors(filters[:colors])
    rel = rel.by_sizes(filters[:sizes])

    rel
  }

  def available?
    active? && published_at.present? && published_at <= Time.current
  end

  def default_variant
    @default_variant ||= Products::DefaultVariantSelector.call(self)
  end

  def price_range
    @price_range ||= Products::PriceCalculationService.calculate_range(self)
  end

  def average_rating
    @average_rating ||= reviews.average(:rating)&.round(1)
  end

  def hit_product?
    return false unless available?
    return @hit_product if defined?(@hit_product)

    @hit_product = (average_rating.to_f >= 4.0 && reviews_count >= 3) ||
      recent_sales_quantity >= 10
  end

  def product_code
    default_variant&.sku || "N/A"
  end

  private

  def recent_sales_quantity
    @recent_sales_quantity ||= order_items.joins(:order)
      .where("orders.created_at > ?", 30.days.ago)
      .sum(:quantity)
  end

  def self.stock_priority_order_sql
    Arel.sql(
      "CASE WHEN COUNT(CASE WHEN product_variants.stock_quantity > 0 THEN 1 END) > 0 THEN 0 ELSE 1 END"
    )
  end

  def self.normalize_ids(ids)
    Array(ids).map(&:presence).compact
  end

  def self.with_stock_priority
    left_joins(:product_variants).group("products.id").order(stock_priority_order_sql)
  end

  def warm_cache_later
    Products::ProductCacheWarmerJob.perform_later(id)
  end
end
