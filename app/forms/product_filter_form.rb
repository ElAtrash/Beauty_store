# frozen_string_literal: true

class ProductFilterForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :in_stock, :boolean, default: false
  attribute :price_range_min, :float
  attribute :price_range_max, :float
  attribute :product_types, StringArrayType.new, default: -> { [] }
  attribute :brands, StringArrayType.new, default: -> { [] }
  attribute :colors, StringArrayType.new, default: -> { [] }
  attribute :sizes, StringArrayType.new, default: -> { [] }
  attribute :skin_types, StringArrayType.new, default: -> { [] }
  attribute :sort_by, :string, default: "popularity"

  # Context for filtering (e.g., 'brand', 'product', 'search')
  attr_accessor :context, :context_resource

  SORT_OPTIONS = {
    "popularity" => "Most Popular",
    "price_asc" => "Price: Low to High",
    "price_desc" => "Price: High to Low",
    "rating" => "Highest Rated",
    "best_sellers" => "Best Sellers"
  }.freeze

  validates :price_range_min, :price_range_max, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :skin_types, inclusion: { in: Product::SKIN_TYPES }, allow_blank: true
  validates :sort_by, inclusion: { in: SORT_OPTIONS.keys }, allow_blank: true

  validate :price_range_logical

  def initialize(params = {}, context: nil, context_resource: nil)
    @context = context
    @context_resource = context_resource
    processed_params = process_nested_price_range(params.to_h.deep_symbolize_keys)
    super(processed_params)
  end

  def price_range_applied?
    price_range_min.present? || price_range_max.present?
  end

  def value_selected?(filter_name, value)
    return false unless public_send(filter_name).is_a?(Array)

    public_send(filter_name).include?(value.to_s)
  end

  alias_method :filter_applied?, :value_selected?

  def to_filter_params
    result = {
      in_stock: in_stock.to_s,
      price_range: build_price_range_params,
      brands: brands.reject(&:blank?),
      product_types: product_types.reject(&:blank?),
      skin_types: skin_types.reject(&:blank?),
      colors: colors.reject(&:blank?),
      sizes: sizes.reject(&:blank?)
    }.compact_blank

    result[:sort_by] = sort_by if sort_by.present?
    result
  end

  alias_method :to_service_params, :to_filter_params

  # Build clean URL for current filter state
  def build_clean_url(base_path)
    FilterUrlBuilder.new(
      base_url: base_path,
      current_params: { sort_by: sort_by }
    ).build_url_from_filters(to_filter_params)
  end

  # Check if brand filters should be hidden (when in brand context)
  def show_brand_filters?
    context != "brand"
  end

  def available_filter_types
    case context
    when "brand"
      [ :in_stock, :price_range, :product_types, :skin_types, :colors, :sizes ]
    when "product"
      [ :in_stock, :price_range, :brands, :product_types, :skin_types, :colors, :sizes ]
    when "search"
      [ :in_stock, :price_range, :brands, :product_types, :skin_types, :colors, :sizes ]
    else
      [ :in_stock, :price_range, :brands, :product_types, :skin_types, :colors, :sizes ]
    end
  end

  def filter_available?(filter_type)
    available_filter_types.include?(filter_type.to_sym)
  end

  private

  def build_price_range_params
    return nil unless price_range_applied?

    {
      min: price_range_min,
      max: price_range_max
    }.compact
  end

  def process_nested_price_range(params)
    price_params = params.delete(:price_range)
    if price_params.is_a?(Hash)
      params[:price_range_min] = price_params[:min]
      params[:price_range_max] = price_params[:max]
    end
    params
  end

  def price_range_logical
    return unless price_range_min.present? && price_range_max.present?

    if price_range_min > price_range_max
      errors.add(:price_range_max, "must be greater than minimum price")
    end
  end
end
