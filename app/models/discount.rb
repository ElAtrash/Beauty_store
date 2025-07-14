class Discount < ApplicationRecord
  monetize :value_cents, allow_nil: true

  validates :code, presence: true, uniqueness: true
  validates :discount_type, presence: true, inclusion: { in: %w[percentage fixed] }
  validates :value_cents, presence: true, numericality: { greater_than: 0 }
  validates :usage_limit, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :valid_now, -> { where("valid_from <= ? AND (valid_until IS NULL OR valid_until >= ?)", Time.current, Time.current) }
  scope :available, -> { active.valid_now.where("usage_limit IS NULL OR usage_count < usage_limit") }

  def active?
    super && valid_now? && usage_available?
  end

  def percentage?
    discount_type == "percentage"
  end

  def fixed?
    discount_type == "fixed"
  end

  def apply_to(amount)
    return amount unless active?

    if percentage?
      discount_amount = amount * (value / 100)
    else
      discount_amount = value
    end

    [ amount - discount_amount, Money.new(0) ].max
  end

  def discount_amount_for(amount)
    return Money.new(0) unless active?

    if percentage?
      amount * (value / 100)
    else
      [ value, amount ].min
    end
  end

  def increment_usage!
    increment!(:usage_count)
  end

  private

  def valid_now?
    return false unless valid_from.present? && valid_from <= Time.current
    valid_until.blank? || valid_until >= Time.current
  end

  def usage_available?
    usage_limit.blank? || usage_count < usage_limit
  end
end
