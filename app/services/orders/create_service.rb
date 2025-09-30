# frozen_string_literal: true

class Orders::CreateService
  include BaseService

  def self.call(**args)
    new(**args).call
  end

  def initialize(cart:, customer_info:)
    @cart = cart
    @customer_info = customer_info
  end

  def call
    validate_required_params(cart: cart, customer_info: customer_info)
    return last_result if last_result&.failure?

    return failure(I18n.t("services.errors.cart_empty")) if cart.cart_items.empty?

    ActiveRecord::Base.transaction do
      order = create_order
      create_order_items(order)
      order.calculate_totals!

      success(resource: order, order: order)
    end
  rescue ActiveRecord::RecordInvalid => e
    log_error("validation error", e)
    failure(I18n.t("services.errors.order_creation_failed"))
  rescue StandardError => e
    log_error("unexpected error", e)
    failure(I18n.t("services.errors.something_went_wrong"))
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
end
