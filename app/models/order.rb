class Order < ApplicationRecord
  belongs_to :user, optional: true, counter_cache: true
  has_many :order_items, dependent: :destroy

  monetize :subtotal_cents
  monetize :tax_total_cents
  monetize :shipping_total_cents
  monetize :discount_total_cents
  monetize :total_cents

  validates :number, presence: true, uniqueness: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  enum :status, {
    pending: "pending",
    processing: "processing",
    shipped: "shipped",
    delivered: "delivered",
    cancelled: "cancelled"
  }

  enum :payment_status, {
    payment_pending: "pending",
    paid: "paid",
    partially_paid: "partially_paid",
    refunded: "refunded"
  }

  before_validation :generate_number, on: :create

  scope :recent, -> { order(created_at: :desc) }

  def total_quantity
    order_items.sum(:quantity)
  end

  def can_be_cancelled?
    pending? || processing?
  end

  def calculate_totals!
    self.subtotal = order_items.sum(&:total_price)
    self.total = subtotal + tax_total + shipping_total - discount_total
    save!
  end

  private

  def generate_number
    return if number.present?

    loop do
      self.number = "ORD-#{SecureRandom.hex(4).upcase}"
      break unless Order.exists?(number: number)
    end
  end
end
