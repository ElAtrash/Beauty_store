# frozen_string_literal: true

class Checkout::DeliverySummaryComponent < ViewComponent::Base
  include StoreInformation

  PICKUP_STATE = :pickup
  ADDRESS_STATE = :address
  SET_ADDRESS_STATE = :set_address

  attr_reader :delivery_method, :address_data, :city

  def initialize(delivery_method:, address_data: {}, city: "Beirut")
    @delivery_method = delivery_method
    @address_data = address_data
    @city = city
  end

  def summary_state
    @summary_state ||= calculate_state
  end

  def pickup_state?
    summary_state == PICKUP_STATE
  end

  def address_state?
    summary_state == ADDRESS_STATE
  end

  def set_address_state?
    summary_state == SET_ADDRESS_STATE
  end

  private

  def calculate_state
    return PICKUP_STATE if delivery_method == "pickup"
    return ADDRESS_STATE if courier_with_address?
    return SET_ADDRESS_STATE if courier_without_address?

    PICKUP_STATE
  end

  def courier_with_address?
    delivery_method == "courier" && address_filled?
  end

  def courier_without_address?
    delivery_method == "courier" && !address_filled?
  end

  def address_filled?
    address_data[:address_line_1].present?
  end

  def formatted_address
    parts = [
      address_data[:address_line_1],
      address_data[:address_line_2],
      address_data[:landmarks]
    ].compact_blank

    parts.join(", ")
  end
end
