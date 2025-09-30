class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :product_variants, through: :cart_items

  validates :session_token, presence: true, uniqueness: true

  before_validation :generate_session_token, on: :create

  scope :abandoned, -> { where.not(abandoned_at: nil) }
  scope :active, -> { where(abandoned_at: nil) }
  scope :by_session_token, ->(token) { where(session_token: token) if token.present? }

  def total_quantity
    cart_items.sum(:quantity)
  end

  def total_price
    total_cents = cart_items.sum("price_snapshot_cents * quantity")
    return Money.new(0, "USD") if total_cents.zero?

    currency = cart_items.first&.price_snapshot_currency || "USD"
    Money.new(total_cents, currency)
  end

  def empty?
    cart_items.empty?
  end

  def ordered_items
    cart_items.includes(product_variant: { product: :brand }).order(:created_at)
  end

  def formatted_total
    total_price&.format || Money.new(0, "USD").format
  end

  def mark_as_abandoned!
    update!(abandoned_at: Time.current)
  end

  private

  def generate_session_token
    return if session_token.present?

    max_attempts = 5
    attempts = 0

    begin
      self.session_token = SecureRandom.hex(16)
      attempts += 1
    rescue ActiveRecord::RecordNotUnique
      if attempts < max_attempts
        retry
      else
        raise ActiveRecord::RecordInvalid.new(self), "Unable to generate unique session token after #{max_attempts} attempts"
      end
    end
  end
end
