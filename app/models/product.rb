class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :brand, optional: true, counter_cache: true

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
  validates :product_attributes, presence: true

  store_accessor :product_attributes,
    :hair_type, :sulfate_free, :paraben_free, :color_safe, :texture,
    :finish, :coverage, :water_resistant, :skin_type, :spf, :alcohol_free,
    :fragrance_family, :longevity, :sillage, :material, :intended_for,
    :application_area, :suitable_for, :cruelty_free

  SKIN_TYPES.each do |skin_type|
    define_method "#{skin_type}_skin?" do
      skin_types&.include?(skin_type)
    end
  end

  scope :active, -> { where(active: true) }
  scope :published, -> { where("published_at IS NOT NULL AND published_at <= ?", Time.current) }
  scope :available, -> { active.published }
  scope :displayable, -> { available.includes(:brand) }
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
    left_joins(:reviews, :product_variants)
      .group("products.id")
      .order(
        Arel.sql("CASE WHEN COUNT(CASE WHEN product_variants.stock_quantity > 0 THEN 1 END) > 0 THEN 0 ELSE 1 END"),
        Arel.sql("COUNT(reviews.id) DESC"),
        :name
      )
  }

  scope :by_price, ->(direction = :asc) {
    direction = direction.to_s.downcase == "desc" ? "DESC" : "ASC"

    joins(:product_variants)
      .group("products.id")
      .order(
        Arel.sql("CASE WHEN COUNT(CASE WHEN product_variants.stock_quantity > 0 THEN 1 END) > 0 THEN 0 ELSE 1 END"),
        Arel.sql("MIN(product_variants.price_cents) #{direction}")
      )
  }

  scope :by_rating, -> {
    left_joins(:reviews, :product_variants)
      .group("products.id")
      .order(
        Arel.sql("CASE WHEN COUNT(CASE WHEN product_variants.stock_quantity > 0 THEN 1 END) > 0 THEN 0 ELSE 1 END"),
        Arel.sql("AVG(COALESCE(reviews.rating, 0)) DESC"),
        :name
      )
  }

  scope :by_best_sellers, -> {
    left_joins(:order_items, :product_variants)
      .group("products.id")
      .order(
        Arel.sql("CASE WHEN COUNT(CASE WHEN product_variants.stock_quantity > 0 THEN 1 END) > 0 THEN 0 ELSE 1 END"),
        Arel.sql("SUM(COALESCE(order_items.quantity, 0)) DESC"),
        :name
      )
  }

  scope :by_stock_status, -> {
    # Orders products by stock status: in-stock first, out-of-stock last
    # Uses a CASE expression to prioritize products with available variants
    left_joins(:product_variants)
      .group("products.id")
      .order(
        Arel.sql(
          "CASE WHEN COUNT(CASE WHEN product_variants.stock_quantity > 0 THEN 1 END) > 0 THEN 0 ELSE 1 END"
        )
      )
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

    # JSONB attribute filters
    # TODO: Implement JSONB attribute filtering
    rel = rel.with_hair_type(filters[:hair_type]) if filters[:hair_type].present?
    rel = rel.with_texture(filters[:texture]) if filters[:texture].present?
    rel = rel.with_finish(filters[:finish]) if filters[:finish].present?
    rel = rel.with_coverage(filters[:coverage]) if filters[:coverage].present?
    rel = rel.with_spf(filters[:spf]) if filters[:spf].present?
    rel = rel.cruelty_free(filters[:cruelty_free]) if filters[:cruelty_free].present?

    rel
  }

  def published?
    published_at.present? && published_at <= Time.current
  end

  def available?
    active? && published?
  end

  def default_variant
    @default_variant ||= default_variant_smart
  end

  def price_range
    @price_range ||= calculate_price_range
  end

  def average_rating
    reviews.average(:rating)&.round(1)
  end

  def hit_product?
    return false unless available?

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

  # Stock state helpers
  def all_variants_out_of_stock?
    !product_variants.in_stock.exists?
  end

  def has_only_size_variants?
    return false unless product_variants.exists?

    # Check if any variants have colors
    has_colors = product_variants.any? { |variant| variant.has_color? }
    # Check if any variants have sizes
    has_sizes = product_variants.any? { |variant| variant.has_size? }

    # Return true only if we have sizes but no colors
    has_sizes && !has_colors
  end

  def has_color_variants?
    return false unless product_variants.exists?

    product_variants.any? { |variant| variant.has_color? }
  end

  def default_selection_reason
    return "No variants available" unless product_variants.exists?

    # Simulate the same logic to determine reasoning
    if find_admin_override_variant
      return "Admin override (is_default = true)"
    end

    unless any_variants_in_stock?
      return "All variants out of stock - showing canonical/fallback"
    end

    if find_bestseller_variant
      return "Performance-based (bestseller with sales/conversion data)"
    end

    if has_only_size_variants?
      return "Size-only product - smallest size selected"
    end

    if has_color_variants? && find_neutral_color_variant(product_variants.in_stock)
      return "Color product - neutral color prioritized"
    end

    if find_entry_level_variant(product_variants.in_stock)
      return "Entry-level pricing strategy (mid-range option)"
    end

    if product_variants.canonical.in_stock.exists?
      return "Canonical variant (merchant-designated)"
    end

    "Position-based fallback (first available)"
  end

  private

  def default_variant_smart
    return nil unless product_variants.exists?

    # Tier 1: Admin Override (Marketing/Visual Hero)
    admin_override = find_admin_override_variant
    return admin_override if admin_override

    # Tier 2: Stock Guard - check if any variants are in stock
    unless any_variants_in_stock?
      return handle_all_out_of_stock
    end

    # Tier 3: Bestseller Rule (Performance-driven)
    bestseller = find_bestseller_variant
    return bestseller if bestseller

    # Tier 4: Smart Defaults (Product-type specific rules)
    smart_default = find_smart_default_variant
    return smart_default if smart_default

    # Tier 5: Canonical/Position Fallback
    find_fallback_variant
  end

  # Tier 1: Admin Override (Marketing/Visual Hero)
  def find_admin_override_variant
    product_variants.marked_default.in_stock.first
  end

  # Tier 2: Stock Guard Helper
  def any_variants_in_stock?
    product_variants.in_stock.exists?
  end

  def handle_all_out_of_stock
    # Show canonical variant with "Notify Me" functionality
    canonical_variant = product_variants.canonical.first
    return canonical_variant if canonical_variant

    # Fallback to position ordering if no canonical set
    product_variants.ordered.first
  end

  # Tier 3: Enhanced Bestseller Logic
  def find_bestseller_variant
    # Combine sales_count and conversion_score with time weighting
    variants_with_performance = product_variants.in_stock
                                              .where("sales_count > 0 OR conversion_score > 0")

    return nil unless variants_with_performance.exists?

    # Order by performance score (sales weighted more heavily)
    variants_with_performance.order(
      Arel.sql("(sales_count * 0.7 + conversion_score * 0.3) DESC")
    ).first
  end

  # Tier 4: Smart Defaults (Product-type specific)
  def find_smart_default_variant
    in_stock_variants = product_variants.in_stock

    # Size-only products: prioritize smallest size
    if has_only_size_variants?
      return in_stock_variants.ordered_by_size.first
    end

    # Color products: prioritize neutral/popular colors
    if has_color_variants?
      neutral_variant = find_neutral_color_variant(in_stock_variants)
      return neutral_variant if neutral_variant
    end

    # Entry-level price consideration for mixed products
    find_entry_level_variant(in_stock_variants)
  end

  # Tier 5: Canonical/Position Fallback
  def find_fallback_variant
    # First try canonical variant if in stock
    canonical = product_variants.canonical.in_stock.first
    return canonical if canonical

    # Otherwise use position ordering
    product_variants.in_stock.ordered.first
  end

  # Helper methods for smart defaults
  def find_neutral_color_variant(variants)
    # Define neutral/popular color terms
    neutral_terms = [
      "nude", "natural", "beige", "brown", "neutral",
      "clear", "transparent", "universal", "classic"
    ]

    # First try to find variants with neutral color names
    neutral_terms.each do |term|
      variant = variants.where("product_variants.color ILIKE ?", "%#{term}%").first
      return variant if variant
    end

    # If no neutral names found, look for specific neutral hex codes
    neutral_hex_codes = [ "#F5DEB3", "#DEB887", "#D2B48C", "#BC9A6A", "#A0522D" ] # Common nude/beige shades
    neutral_hex_codes.each do |hex|
      variant = variants.where(color_hex: hex).first
      return variant if variant
    end

    nil
  end

  def find_entry_level_variant(variants)
    # For products with mixed variants, find a good entry point
    # Prefer mid-range price (not cheapest, not most expensive)
    sorted_by_price = variants.order(:price_cents)
    variant_count = sorted_by_price.count

    return sorted_by_price.first if variant_count <= 2

    # Pick the second cheapest option for better perceived value
    sorted_by_price.offset(1).first
  end

  def calculate_price_range
    return nil unless product_variants.exists?

    prices = product_variants.pluck(:price_cents).map { |cents| Money.new(cents) }
    min_price = prices.min
    max_price = prices.max

    min_price == max_price ? min_price : (min_price..max_price)
  end
end
