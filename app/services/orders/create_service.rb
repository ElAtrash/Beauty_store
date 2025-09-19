# frozen_string_literal: true

class Orders::CreateService
  def self.call(**args)
    new(**args).call
  end

  def initialize(cart:, customer_info:)
    @cart = cart
    @customer_info = customer_info
  end

  def call
    return failure("Cart is required") unless cart
    return failure("Cart is empty") if cart.cart_items.empty?
    return failure("Customer information is required") unless customer_info

    ActiveRecord::Base.transaction do
      order = create_order
      create_order_items(order)
      order.calculate_totals!

      success(resource: order, order: order)
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Orders::CreateService validation error: #{e.message}"
    failure("We couldn't create your order. Please check your information and try again.")
  rescue StandardError => e
    Rails.logger.error "Orders::CreateService unexpected error: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    failure("Something went wrong. Please try again.")
  end

  private

  attr_reader :cart, :customer_info

  def create_order
    Order.create!(
      user: Current.user,
      email: customer_info[:email],
      phone_number: customer_info[:phone_number],
      billing_address: build_billing_address,
      delivery_method: customer_info[:delivery_method],
      delivery_notes: customer_info[:delivery_notes],
      delivery_date: customer_info[:delivery_date],
      delivery_time_slot: customer_info[:delivery_time_slot],
      payment_status: determine_payment_status,
      fulfillment_status: "unfulfilled"
    )
  end

  def create_order_items(order)
    cart.cart_items.find_each do |cart_item|
      OrderItem.create!(
        order: order,
        product_variant: cart_item.product_variant,
        quantity: cart_item.quantity,
        unit_price_cents: cart_item.price_snapshot_cents,
        unit_price_currency: cart_item.price_snapshot_currency
      )
    end
  end

  def build_billing_address
    return {} unless courier_delivery?

    {
      first_name: customer_info[:first_name],
      last_name: customer_info[:last_name],
      address_line_1: customer_info[:address_line_1],
      address_line_2: customer_info[:address_line_2],
      city: customer_info[:city],
      landmarks: customer_info[:landmarks]
    }.compact_blank
  end

  def courier_delivery?
    customer_info[:delivery_method] == "courier"
  end

  def determine_payment_status
    case customer_info[:payment_method]
    when "cod"
      "cod_due"
    else
      "payment_pending"
    end
  end

  def success(resource: nil, order: nil, **metadata)
    BaseResult.new(
      success: true,
      resource: resource,
      order: order,
      **metadata
    )
  end

  def failure(errors, **metadata)
    BaseResult.new(
      success: false,
      errors: Array(errors),
      **metadata
    )
  end
end
