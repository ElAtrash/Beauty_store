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
  validates :phone_number, presence: true
  validates :delivery_date, presence: true, if: :requires_delivery_scheduling?
  validates :delivery_time_slot, presence: true, if: :requires_delivery_scheduling?

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
    refunded: "refunded",
    cod_due: "cod_due"
  }

  enum :delivery_method, {
    courier: "courier",
    pickup: "pickup"
  }

  enum :fulfillment_status, {
    unfulfilled: "unfulfilled",
    packed: "packed",
    dispatched: "dispatched"
  }

  before_validation :generate_number, on: :create
  before_save :set_delivery_scheduled_at

  scope :recent, -> { order(created_at: :desc) }

  def total_quantity
    order_items.sum(:quantity)
  end

  def calculate_totals!
    self.subtotal = order_items.sum(&:total_price)
    self.total = subtotal + tax_total + shipping_total - discount_total
    save!
  end

  def requires_delivery_scheduling?
    courier? || (pickup? && delivery_date.present?)
  end

  private

  def generate_number
    return if number.present?

    loop do
      self.number = "ORD-#{SecureRandom.hex(4).upcase}"
      break unless Order.exists?(number: number)
    end
  end

  def set_delivery_scheduled_at
    return unless delivery_date && delivery_time_slot

    self.delivery_scheduled_at = TimeSlotParser.parse_delivery_time(delivery_time_slot, delivery_date)
  end
end
