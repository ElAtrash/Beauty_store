# frozen_string_literal: true

class Checkout::Modals::AddressModalComponent < Modal::BaseComponent
  include StoreInformation

  attr_reader :form, :city

  def initialize(form:, city:)
    @form = form
    @city = city
    super(
      id: "address-modal",
      title: "Delivery Address",
      size: :medium,
      position: :right,
      data: {
        controller: "address-modal",
        "address-modal-city-value": city,
        "address-modal-delivery-summary-url-value": "/checkout/delivery_summary",
        "address-modal-delivery-summary-outlet": ".delivery-summary",
        "address-modal-modal-outlet": "#address-modal",
        "address-modal-form-validation-outlet": ".checkout-form-container"
      }
    )
  end

  def delivery_card_props
    {
      icon: :truck,
      title: "Delivering to #{city}"
    }
  end

  def submit_button_props
    {
      text: "Bring it here",
      css_class: "btn-interactive btn-full btn-lg",
      data_action: "click->address-modal#submitAddress",
      data: { "address-modal-target": "submitButton" }
    }
  end
end
