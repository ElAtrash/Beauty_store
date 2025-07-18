class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :product_variants, through: :cart_items

  validates :session_id, presence: true, if: -> { user.blank? }

  scope :abandoned, -> { where.not(abandoned_at: nil) }
  scope :active, -> { where(abandoned_at: nil) }

  def total_quantity
    cart_items.sum(:quantity)
  end

  def total_price
    cart_items.sum { |item| item.total_price }
  end

  def empty?
    cart_items.empty?
  end

  def add_variant(product_variant, quantity = 1)
    find_or_update_cart_item(product_variant, quantity)
  end

  def remove_variant(product_variant)
    cart_items.find_by(product_variant: product_variant)&.destroy
  end

  def mark_as_abandoned!
    update!(abandoned_at: Time.current)
  end

  private

  def find_or_update_cart_item(product_variant, quantity)
    current_item = cart_items.find_by(product_variant: product_variant)

    if current_item
      current_item.quantity += quantity
      current_item.save!
    else
      cart_items.create!(product_variant: product_variant, quantity: quantity)
    end
  end
end
