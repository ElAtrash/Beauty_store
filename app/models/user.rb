class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  LEBANESE_GOVERNORATES = [
    "Beirut", "Mount Lebanon", "North Lebanon", "South Lebanon",
    "Bekaa", "Nabatieh", "Akkar", "Baalbek-Hermel"
  ].freeze

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, format: { with: /\A\+?[0-9\s\-\(\)]+\z/ }, allow_blank: true
  validates :preferred_language, inclusion: { in: %w[ar en] }, allow_blank: true
  validates :governorate, inclusion: { in: LEBANESE_GOVERNORATES }, allow_blank: true
  validates :first_name, :last_name, length: { minimum: 2, maximum: 50 }, allow_blank: true
  validates :city, length: { maximum: 100 }, allow_blank: true
  validates :date_of_birth, comparison: { less_than: Date.current }, allow_blank: true

  scope :by_language, ->(lang) { where(preferred_language: lang) }
  scope :by_governorate, ->(gov) { where(governorate: gov) }
  scope :by_city, ->(city) { where(city: city) }
  scope :admins, -> { where(admin: true) }
  scope :customers, -> { where(admin: false) }
  scope :adults, -> { where("date_of_birth < ?", 18.years.ago) }

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

  def age
    return nil unless date_of_birth
    ((Date.current - date_of_birth) / 365.25).floor
  end

  def full_address
    [ city, governorate ].compact.join(", ")
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :phone_number, with: ->(p) { p.gsub(/\s/, "") if p }
  normalizes :first_name, :last_name, with: ->(name) { name.strip.titleize if name }
  normalizes :city, with: ->(city) { city.strip.titleize if city }
end
