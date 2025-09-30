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
  validates :delivery_date, presence: true, if: :courier?
  validates :delivery_time_slot, presence: true, if: :courier?
  validate :delivery_time_slot_format, if: :courier?

  enum :payment_status, {
    payment_pending: "pending",
    paid: "paid",
    refunded: "refunded",
    cod_due: "cod_due"
  }

  enum :delivery_method, { courier: "courier", pickup: "pickup" }

  enum :fulfillment_status, {
    unfulfilled: "unfulfilled",
    processing: "processing",
    packed: "packed",
    dispatched: "dispatched",
    delivered: "delivered",
    picked_up: "picked_up",
    cancelled: "cancelled"
  }

  before_validation :generate_number, on: :create

  def total_quantity
    order_items.sum(:quantity)
  end

  def calculate_totals!
    self.subtotal = order_items.sum(&:total_price)
    self.total = subtotal + tax_total + shipping_total - discount_total
    save!
  end

  def formatted_total
    total&.format || Money.new(0, "USD").format
  end

  def formatted_subtotal
    subtotal&.format || Money.new(0, "USD").format
  end

  def formatted_shipping_total
    shipping_total&.format || Money.new(0, "USD").format
  end

  def show_whats_next?
    !delivered? && !picked_up? && !cancelled?
  end

  private

  def delivery_time_slot_format
    return if delivery_time_slot.blank?

    unless TimeSlotParser.valid_delivery_time_slot?(delivery_time_slot)
      errors.add(:delivery_time_slot, "must be one of: 09:00-12:00, 12:00-15:00, 15:00-18:00, 18:00-21:00")
    end
  end

  def generate_number
    return if number.present?

    loop do
      self.number = "ORD-#{SecureRandom.hex(4).upcase}"
      break unless Order.exists?(number: number)
    end
  end
end
