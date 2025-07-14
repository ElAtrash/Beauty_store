class Review < ApplicationRecord
  belongs_to :product, counter_cache: true
  belongs_to :user

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :product_id }

  enum status: {
    pending: "pending",
    approved: "approved",
    rejected: "rejected"
  }

  scope :by_rating, ->(rating) { where(rating: rating) }
  scope :recent, -> { order(created_at: :desc) }
end
