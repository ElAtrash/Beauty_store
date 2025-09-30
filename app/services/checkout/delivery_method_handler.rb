# frozen_string_literal: true

class Checkout::DeliveryMethodHandler
  def self.call(form:, delivery_method: nil, address_params: {})
    new(form, delivery_method, address_params).call
  end

  def initialize(form, delivery_method, address_params)
    @form = form
    @raw_delivery_method = delivery_method
    @delivery_method = CheckoutForm.normalize_delivery_method(delivery_method) if delivery_method.present?
    @address_params = address_params || {}
  end

  def call
    update_params = {}
    update_params[:delivery_method] = delivery_method if raw_delivery_method.present?
    update_params.merge!(address_params) if address_params.any?

    form.update_from_params(update_params) if update_params.any?
    form
  end

  private

  attr_reader :form, :delivery_method, :address_params, :raw_delivery_method
end
