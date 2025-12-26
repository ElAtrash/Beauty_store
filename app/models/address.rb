# frozen_string_literal: true

class Address < ApplicationRecord
  belongs_to :user

  # Validations
  validates :label, length: { maximum: 50 }, allow_blank: true
  validates :label, uniqueness: { scope: :user_id, conditions: -> { where(deleted_at: nil) } }, allow_blank: true
  validates :address_line_1, presence: true, length: { maximum: 255 }
  validates :address_line_2, length: { maximum: 255 }, allow_blank: true
  validates :city, presence: true, length: { maximum: 100 }
  validates :governorate, presence: true, inclusion: { in: User::LEBANESE_GOVERNORATES }
  validates :landmarks, length: { maximum: 500 }, allow_blank: true
  validates :phone_number, phone: true, allow_blank: true

  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :default_address, -> { active.where(default: true) }
  scope :non_default, -> { active.where(default: false) }
  scope :by_label, ->(label) { active.where(label: label) }
  scope :recently_used, -> { active.order(updated_at: :desc) }

  # Callbacks
  before_validation :generate_label_if_blank, on: :create
  before_save :ensure_only_one_default, if: :default?

  # Soft delete
  def soft_delete
    update(deleted_at: Time.current, default: false)
  end

  def deleted?
    deleted_at.present?
  end

  # Display helpers
  def full_address
    [ address_line_1, address_line_2, city, governorate ].compact.join(", ")
  end

  def short_address
    [ address_line_1, city ].compact.join(", ")
  end

  def display_label
    label.to_s
  end

  # Check if this is user's only address
  def only_address?
    user.addresses.active.count == 1
  end

  private

  def generate_label_if_blank
    return if label.present?

    # Get count of user's active addresses (not including this one)
    address_count = user&.addresses&.active&.count || 0

    # Generate label: "Address 1", "Address 2", etc.
    self.label = "Address #{address_count + 1}"
  end

  def ensure_only_one_default
    return unless default_changed? && default?

    # Unset default for all other addresses for this user
    self.class.where(user_id: user_id, default: true)
               .where.not(id: id)
               .update_all(default: false)
  end
end
