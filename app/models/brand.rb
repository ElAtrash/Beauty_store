class Brand < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :products, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  scope :featured, -> { where(featured: true) }

  after_commit :expire_navigation_cache

  private

  def expire_navigation_cache
    Rails.cache.delete("brands_alphabet_navigation")
  end
end
