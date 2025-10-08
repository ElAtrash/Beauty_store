# frozen_string_literal: true

class CheckoutForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :phone_number, :string
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :address_line_1, :string
  attribute :address_line_2, :string
  attribute :city, :string, default: -> { StoreConfigurationService::DEFAULT_CITY }
  attribute :governorate, :string, default: -> { StoreConfigurationService::DEFAULT_GOVERNORATE }
  attribute :landmarks, :string
  attribute :delivery_method, :string, default: "pickup"
  attribute :delivery_notes, :string
  attribute :delivery_date, :date
  attribute :delivery_time_slot, :string
  attribute :payment_method, :string, default: "cod"
  attribute :save_address_as_default, :boolean, default: false
  attribute :save_profile_info, :boolean, default: false
  attribute :selected_address_id, :integer

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, presence: true, phone: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :address_line_1, presence: true, if: :courier_delivery?
  validates :city, presence: true
  validates :delivery_method, inclusion: { in: %w[courier pickup] }
  validates :delivery_date, presence: true, if: :courier_delivery?
  validates :delivery_time_slot, presence: true, if: :courier_delivery?
  validates :payment_method, inclusion: { in: %w[cod] } # Only COD for Phase 1

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def courier_delivery?
    delivery_method == "courier"
  end

  def formatted_phone
    return "" if phone_number.blank?
    "+961#{self.class.normalize_phone(phone_number)}"
  end

  def shipping_address
    {
      first_name: first_name,
      last_name: last_name,
      address_line_1: address_line_1,
      address_line_2: address_line_2,
      city: city,
      governorate: governorate,
      landmarks: landmarks,
      phone: formatted_phone
    }
  end

  def billing_address
    # For now, billing = shipping
    shipping_address
  end

  def to_h
    {
      email: email,
      phone_number: formatted_phone,
      full_name: full_name,
      shipping_address: shipping_address,
      billing_address: billing_address,
      delivery_method: delivery_method,
      delivery_date: delivery_date,
      delivery_time_slot: delivery_time_slot,
      payment_method: payment_method,
      delivery_notes: delivery_notes,
      save_address_as_default: save_address_as_default
    }
  end

  def persist_to_session(session)
    session[Checkout::FormStateService::CHECKOUT_FORM_DATA_KEY] = attributes.compact_blank
  end

  def clear_from_session(session)
    session.delete(Checkout::FormStateService::CHECKOUT_FORM_DATA_KEY)
  end

  def has_partial_data?
    email.present? ||
    first_name.present? ||
    delivery_method.present? ||
    address_line_1.present?
  end

  def has_complete_user_data?
    email.present? && first_name.present? && last_name.present?
  end

  def self.from_session(session_data)
    new(session_data || {})
  end

  def self.normalize_delivery_method(method)
    %w[courier pickup].include?(method) ? method : "pickup"
  end

  def update_from_params(params)
    assign_attributes(params)
    self
  end

  # Pre-fill from logged-in user profile
  def self.from_user(user, session)
    form = from_session(session[Checkout::FormStateService::CHECKOUT_FORM_DATA_KEY])
    return form unless user

    form.email ||= user.email_address
    form.first_name ||= user.first_name
    form.last_name ||= user.last_name
    form.phone_number ||= normalize_phone(user.phone_number)

    # Use Address model for pre-filling
    if user.default_address
      addr = user.default_address
      form.selected_address_id = addr.id
      form.address_line_1 ||= addr.address_line_1
      form.address_line_2 ||= addr.address_line_2
      form.city ||= addr.city
      form.governorate ||= addr.governorate
      form.landmarks ||= addr.landmarks
      form.phone_number ||= normalize_phone(addr.phone_number) if addr.phone_number.present?
    else
      form.city ||= user.city if user.city.present?
      form.governorate ||= default_governorate
    end

    form
  end

  def self.default_governorate
    StoreConfigurationService::DEFAULT_GOVERNORATE
  end

  def self.default_city
    StoreConfigurationService::DEFAULT_CITY
  end

  def self.normalize_phone(phone)
    return "" if phone.blank?
    phone.gsub(/\D/, "").sub(/^961/, "")
  end

  # Populate form from selected saved address
  def populate_from_address(address)
    return unless address

    self.selected_address_id = address.id
    self.address_line_1 = address.address_line_1
    self.address_line_2 = address.address_line_2
    self.city = address.city
    self.governorate = address.governorate
    self.landmarks = address.landmarks
    self.phone_number = self.class.normalize_phone(address.phone_number) if address.phone_number.present?
  end
end
