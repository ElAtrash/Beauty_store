class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_one :customer_profile, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :wishlists, dependent: :destroy

  LEBANESE_GOVERNORATES = [
    "Beirut", "Mount Lebanon", "North Lebanon", "South Lebanon",
    "Bekaa", "Nabatieh", "Akkar", "Baalbek-Hermel"
  ].freeze

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, format: { with: /\A\+?[0-9\s\-\(\)]+\z/ }, allow_blank: true
  validates :governorate, inclusion: { in: LEBANESE_GOVERNORATES }, allow_blank: true
  validates :first_name, :last_name, length: { minimum: 2, maximum: 50 }, allow_blank: true
  validates :city, length: { maximum: 100 }, allow_blank: true
  validates :date_of_birth, comparison: { less_than: Date.current }, allow_blank: true

  enum :preferred_language, { ar: "ar", en: "en" }, prefix: true

  scope :by_language, ->(lang) { where(preferred_language: lang) }
  scope :by_governorate, ->(gov) { where(governorate: gov) }
  scope :admins, -> { where(admin: true) }
  scope :adults, -> { where("date_of_birth < ?", 18.years.ago) }

  def display_name
    full_name.present? ? full_name : email_address
  end

  def rtl_language?
    preferred_language_ar?
  end

  def age
    return nil unless date_of_birth

    calculate_age_from_birth_date
  end

  def full_address
    [ city, governorate ].compact.join(", ")
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :phone_number, with: ->(phone) { phone.gsub(/[\s\-\(\)]/, "") if phone }
  normalizes :first_name, :last_name, with: ->(name) { name.strip.titleize if name }
  normalizes :city, with: ->(city) { city.strip.titleize if city }

  private

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def calculate_age_from_birth_date
    ((Time.zone.now - date_of_birth.to_time) / 1.year.seconds).floor
  end
end
