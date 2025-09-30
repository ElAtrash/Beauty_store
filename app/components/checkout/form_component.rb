# frozen_string_literal: true

class Checkout::FormComponent < ViewComponent::Base
  include StoreInformation

  delegate :delivery_method_options, :payment_method_options, :payment_method_descriptions,
           to: :StoreConfigurationService

  delegate :city, to: :StoreConfigurationService, prefix: :store

  def initialize(checkout_form:, cart:)
    @checkout_form = checkout_form
    @cart = cart
  end

  private

  attr_reader :checkout_form, :cart

  def effective_delivery_method
    checkout_form.delivery_method || "pickup"
  end

  def effective_city
    checkout_form.city || store_city
  end

  def delivery_summary_address_data
    {
      address_line_1: checkout_form.address_line_1,
      address_line_2: checkout_form.address_line_2,
      landmarks: checkout_form.landmarks
    }
  end
end
