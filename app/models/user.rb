class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  LEBANESE_GOVERNORATES = [
    "Beirut", "Mount Lebanon", "North Lebanon", "South Lebanon",
    "Bekaa", "Nabatieh", "Akkar", "Baalbek-Hermel"
  ].freeze

  validates :email_address, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true
  validates :phone_number, format: { with: /\A\+?[0-9\s\-\(\)]+\z/ }
  validates :preferred_language, inclusion: { in: %w[ar en fr] }
  validates :governorate, inclusion: { in: LEBANESE_GOVERNORATES }

  scope :by_language, ->(lang) { where(preferred_language: lang) }
  scope :by_governorate, ->(gov) { where(governorate: gov) }

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    full_name.present? ? full_name : email_address
  end

  def arabic_speaker?
    preferred_language == "ar"
  end

  def rtl_language?
    arabic_speaker?
  end

  def preferred_currency
    governorate == "Beirut" ? "USD" : "LBP"
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :phone_number, with: ->(p) { p.gsub(/\s/, "") if p }
end
