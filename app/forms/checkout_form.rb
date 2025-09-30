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
  attribute :city, :string, default: "Beirut"
  attribute :landmarks, :string
  attribute :delivery_method, :string, default: "pickup"
  attribute :delivery_notes, :string
  attribute :delivery_date, :date
  attribute :delivery_time_slot, :string
  attribute :payment_method, :string, default: "cod"

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, presence: true, format: {
    with: /\A(\+961|961)?(70|71|03|76|81)\d{6}\z/,
    message: ->(object, data) { I18n.t("validation.errors.phone_lebanon_invalid") }
  }
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
    number = phone_number.gsub(/\D/, "")
    number = number.sub(/^961/, "") if number.start_with?("961")
    "+961#{number}"
  end

  def shipping_address
    {
      first_name: first_name,
      last_name: last_name,
      address_line_1: address_line_1,
      address_line_2: address_line_2,
      city: city,
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
      delivery_notes: delivery_notes
    }
  end

  def persist_to_session(session)
    session[:checkout_form_data] = attributes.compact_blank
  end

  def clear_from_session(session)
    session.delete(:checkout_form_data)
  end

  def valid_for_persistence?
    email.present? ||
    first_name.present? ||
    delivery_method.present? ||
    address_line_1.present?
  end

  def valid_for_full_persistence?
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
end
