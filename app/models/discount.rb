class Discount < ApplicationRecord
  monetize :value_cents, allow_nil: true

  validates :code, presence: true, uniqueness: true
  validates :value_cents, presence: true, numericality: { greater_than: 0 }
  validates :usage_limit, numericality: { greater_than: 0 }, allow_nil: true
  validates :valid_until, comparison: { greater_than: :valid_from }, allow_nil: true, if: :valid_from?

  enum :discount_type, { percentage: "percentage", fixed: "fixed" }

  def active?
    super && valid_now? && usage_available?
  end

  def apply_to(amount)
    return amount unless active?

    discount_amount = discount_amount_for(amount)
    [ amount - discount_amount, Money.new(0) ].max
  end

  def increment_usage!
    increment!(:usage_count)
  end

  private

  def valid_now?
    return false if valid_from.present? && valid_from > Time.current

    valid_until.blank? || valid_until >= Time.current
  end

  def usage_available?
    usage_limit.blank? || usage_count < usage_limit
  end

  def discount_amount_for(amount)
    return Money.new(0) unless active?

    amount = Money.new(amount) unless amount.is_a?(Money)

    if percentage?
      percentage_value = value_cents / 100.0 / 100.0
      amount * percentage_value
    else
      [ value, amount ].min
    end
  end
end
