class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :brand, optional: true

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

  validates :skin_types, inclusion: { in: SKIN_TYPES }, allow_blank: true

  SKIN_TYPES.each do |skin_type|
    define_method "#{skin_type}_skin?" do
      skin_types&.include?(skin_type)
    end
  end

  scope :active, -> { where(active: true) }
  scope :published, -> { where("published_at IS NOT NULL AND published_at <= ?", Time.current) }
  scope :available, -> { active.published }
  scope :by_skin_type, ->(skin_type) { where("skin_types @> ARRAY[?]::varchar[]", skin_type) }

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

  private

  def calculate_price_range
    return nil unless product_variants.exists?

    prices = product_variants.pluck(:price_cents).map { |cents| Money.new(cents) }
    min_price = prices.min
    max_price = prices.max

    min_price == max_price ? min_price : (min_price..max_price)
  end
end
