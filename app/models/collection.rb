class Collection < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :collection_products, dependent: :destroy
  has_many :products, through: :collection_products

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }
end
