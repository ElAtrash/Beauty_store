class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :destroy

  has_many :categorizations, dependent: :destroy
  has_many :products, through: :categorizations

  validates :name, presence: true, uniqueness: { scope: :parent_id }
  validates :slug, presence: true, uniqueness: true

  scope :root, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position) }

  def root?
    parent_id.nil?
  end

  def leaf?
    children.empty?
  end
end
