# frozen_string_literal: true

class Checkout::Modals::AddressModalComponent < Modal::BaseComponent
  include StoreInformation

  attr_reader :checkout_form, :city, :user

  def initialize(checkout_form:, city:, user: nil)
    @checkout_form = checkout_form
    @city = city
    @user = user
    super(
      id: "address-modal",
      title: modal_title,
      size: :medium,
      position: :right,
      data: modal_data_attributes
    )
  end

  def has_saved_addresses?
    user&.addresses&.active&.any?
  end

  def user_addresses
    return [] unless user
    user.addresses.active.recently_used
  end

  def selected_address
    return nil unless user

    # checkout_form is the CheckoutForm model
    selected_id = checkout_form&.selected_address_id
    return nil unless selected_id

    user.addresses.find_by(id: selected_id) || user.default_address
  end

  def delivery_card_props
    {
      icon: :truck,
      title: "Delivering to #{city}"
    }
  end

  private

  def modal_title
    "Choose Delivery Address"
  end

  def modal_data_attributes
    {
      controller: "address-modal",
      "address-modal-city-value": city,
      "address-modal-delivery-summary-url-value": "/checkout/delivery_summary",
      "address-modal-delivery-summary-outlet": ".delivery-summary",
      "address-modal-modal-outlet": "#address-modal",
      "address-modal-form-validation-outlet": ".checkout-form-container"
    }
  end
end
