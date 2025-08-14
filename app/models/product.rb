class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :brand, optional: true, counter_cache: true

  has_many_attached :images
  has_one_attached :featured_image
  has_many :product_variants, dependent: :destroy
  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :collection_products, dependent: :destroy
  has_many :collections, through: :collection_products
  has_many :reviews, dependent: :destroy
  has_many :order_items, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  SKIN_TYPES = %w[oily dry combination sensitive normal].freeze
  HAIR_TYPES = %w[straight wavy curly coily fine thick damaged colored].freeze

  validates :skin_types, inclusion: { in: SKIN_TYPES }, allow_blank: true

  SKIN_TYPES.each do |skin_type|
    define_method "#{skin_type}_skin?" do
      skin_types&.include?(skin_type)
    end
  end

  scope :active, -> { where(active: true) }
  scope :published, -> { where("published_at IS NOT NULL AND published_at <= ?", Time.current) }
  scope :available, -> { active.published }
  scope :displayable, -> { available.includes(:brand, :featured_image_attachment) }
  scope :in_stock, -> {
    joins(:product_variants)
      .where("product_variants.stock_quantity > 0")
      .distinct
  }

  scope :by_brand, ->(brand_ids) { where(brand_id: Array(brand_ids).compact.reject(&:blank?)) if Array(brand_ids).any?(&:present?) }
  scope :by_price_range, ->(min, max) {
    return all unless min.present? || max.present?
    rel = joins(:product_variants)
    rel = rel.where("product_variants.price_cents >= ?", (min.to_f * 100).to_i) if min.present?
    rel = rel.where("product_variants.price_cents <= ?", (max.to_f * 100).to_i) if max.present?
    rel.distinct
  }
  scope :by_categories, ->(category_ids) {
    ids = Array(category_ids).compact.reject(&:blank?)
    joins(:categories).where(categories: { id: ids }).distinct if ids.any?
  }
  scope :by_skin_types, ->(types) {
    valid_types = Array(types).compact.reject(&:blank?) & SKIN_TYPES
    valid_types.reduce(all) { |rel, type| rel.where("skin_types @> ARRAY[?]::varchar[]", type) } if valid_types.any?
  }
  scope :by_colors, ->(colors) {
    valid_colors = Array(colors).compact.reject(&:blank?)
    joins(:product_variants).where(product_variants: { color: valid_colors }).distinct if valid_colors.any?
  }
  scope :by_sizes, ->(sizes) {
    valid_sizes = Array(sizes).compact.reject(&:blank?)
    joins(:product_variants).where(product_variants: { size_type: valid_sizes }).distinct if valid_sizes.any?
  }

  scope :by_popularity, -> {
    left_joins(:reviews)
      .group("products.id")
      .order(Arel.sql("COUNT(reviews.id) DESC"), :name)
  }

  scope :by_price, ->(direction = :asc) {
    direction = direction.to_s.downcase == "desc" ? "DESC" : "ASC"

    joins(:product_variants)
      .group("products.id")
      .order(Arel.sql("MIN(product_variants.price_cents) #{direction}"))
  }

  scope :by_rating, -> {
    left_joins(:reviews)
      .group("products.id")
      .order(Arel.sql("AVG(COALESCE(reviews.rating, 0)) DESC"), :name)
  }

  scope :by_best_sellers, -> {
    left_joins(:order_items)
      .group("products.id")
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

  def published?
    published_at.present? && published_at <= Time.current
  end

  def available?
    active? && published?
  end

  def default_variant
    @default_variant ||= product_variants.ordered.first
  end

  def price_range
    @price_range ||= calculate_price_range
  end

  def average_rating
    reviews.average(:rating)&.round(1)
  end

  def hit_product?
    # You can customize this logic based on your business requirements
    # For now, let's consider products with high ratings and recent orders as hit products
    return false unless available?

    # Consider it a hit if it has good ratings and recent sales
    (average_rating.to_f >= 4.0 && reviews.count >= 3) ||
    order_items.joins(:order).where("orders.created_at > ?", 30.days.ago).sum(:quantity) >= 10
  end

  def rating
    average_rating
  end

  def reviews_count
    reviews.count
  end

  def product_code
    default_variant&.sku || "N/A"
  end

  private

  def calculate_price_range
    return nil unless product_variants.exists?

    prices = product_variants.pluck(:price_cents).map { |cents| Money.new(cents) }
    min_price = prices.min
    max_price = prices.max

    min_price == max_price ? min_price : (min_price..max_price)
  end
end
