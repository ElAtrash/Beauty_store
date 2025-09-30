# frozen_string_literal: true

class Orders::ReorderService
  include BaseService

  def self.call(order:, user: nil, session: nil, cart_token: nil)
    new(order: order, user: user, session: session, cart_token: cart_token).call
  end

  def initialize(order:, user: nil, session: nil, cart_token: nil)
    @order = order
    @user = user
    @session = session
    @cart_token = cart_token
    @cart = nil
    @success_items = []
    @failed_items = []
  end

  def call
    validate_required_params(order: order)
    return last_result if last_result&.failure?

    validate_order_items
    return last_result if last_result&.failure?

    setup_cart
    return last_result if last_result&.failure?

    process_order_items

    if @success_items.any?
      success_result
    elsif @failed_items.any?
      failure_result_with_items
    else
      empty_result
    end
  rescue => e
    log_error("unexpected error", e)
    failure(I18n.t("checkout.reorder.errors.processing_error"), cart: @cart)
  end

  private

  attr_reader :order, :cart, :success_items, :failed_items, :user, :session, :cart_token

  def validate_order_items
    if order&.order_items&.empty?
      @last_result = failure(I18n.t("checkout.reorder.errors.no_items_added"))
    end
  end

  def setup_cart
    result = Carts::FindOrCreateService.call(
      user: user,
      session: session,
      cart_token: cart_token
    )

    if result.success?
      @cart = result.cart
    else
      @last_result = failure(I18n.t("services.errors.something_went_wrong"))
    end
  end

  def process_order_items
    order.order_items.includes(:product_variant, product_variant: :product).each do |order_item|
      process_single_item(order_item)
    end
  end

  def process_single_item(order_item)
    product_variant = order_item.product_variant
    requested_quantity = order_item.quantity

    unless product_variant&.available?
      add_failed_item(order_item, I18n.t("checkout.reorder.messages.product_not_available"))
      return
    end

    unless product_variant.in_stock?
      add_failed_item(order_item, I18n.t("checkout.reorder.messages.out_of_stock"))
      return
    end

    current_cart_quantity = cart.cart_items.find_by(product_variant: product_variant)&.quantity || 0

    validation_result = Carts::QuantityService.validate_quantity(
      requested_quantity,
      product_variant: product_variant,
      existing_quantity: current_cart_quantity
    )

    if validation_result.success?
      add_item_result = Carts::AddItemService.call(
        cart: cart,
        product_variant: product_variant,
        quantity: requested_quantity
      )

      if add_item_result.success?
        add_success_item(order_item, requested_quantity)
      else
        add_failed_item(order_item, add_item_result.errors.join(", "))
      end
    else
      max_available = calculate_max_available_quantity(product_variant, current_cart_quantity)

      if max_available > 0
        add_item_result = Carts::AddItemService.call(
          cart: cart,
          product_variant: product_variant,
          quantity: max_available
        )

        if add_item_result.success?
          add_partial_success_item(order_item, max_available, requested_quantity)
        else
          add_failed_item(order_item, add_item_result.errors.join(", "))
        end
      else
        add_failed_item(order_item, I18n.t("checkout.reorder.messages.cart_limit_reached"))
      end
    end
  end

  def calculate_max_available_quantity(product_variant, current_cart_quantity)
    max_by_stock = product_variant.stock_quantity - current_cart_quantity
    max_by_system = Carts::QuantityService::MAX_QUANTITY - current_cart_quantity

    [ max_by_stock, max_by_system ].min.clamp(0, Float::INFINITY)
  end

  def add_success_item(order_item, quantity)
    @success_items << {
      product_name: order_item.product_name,
      variant_name: order_item.variant_name,
      quantity: quantity,
      status: :success
    }
  end

  def add_partial_success_item(order_item, added_quantity, requested_quantity)
    @success_items << {
      product_name: order_item.product_name,
      variant_name: order_item.variant_name,
      quantity: added_quantity,
      requested_quantity: requested_quantity,
      status: :partial
    }
  end

  def add_failed_item(order_item, reason)
    @failed_items << {
      product_name: order_item.product_name,
      variant_name: order_item.variant_name,
      quantity: order_item.quantity,
      reason: reason,
      status: :failed
    }
  end

  def success_result
    success(
      cart: cart,
      success_items: success_items,
      failed_items: failed_items,
      message: build_success_message
    )
  end

  def failure_result_with_items
    failure(
      build_failure_message,
      cart: cart,
      success_items: success_items,
      failed_items: failed_items
    )
  end

  def empty_result
    failure(
      I18n.t("checkout.reorder.errors.no_items_added"),
      cart: cart
    )
  end

  def build_success_message
    messages = []

    full_success_count = success_items.count { |item| item[:status] == :success }
    partial_success_count = success_items.count { |item| item[:status] == :partial }

    if full_success_count > 0
      messages << I18n.t("checkout.reorder.messages.items_added", count: full_success_count)
    end

    if partial_success_count > 0
      messages << I18n.t("checkout.reorder.messages.items_partially_added", count: partial_success_count)
    end

    if failed_items.any?
      messages << I18n.t("checkout.reorder.messages.items_unavailable", count: failed_items.count)
    end

    messages.join(", ")
  end

  def build_failure_message
    if failed_items.any?
      reasons = failed_items.map { |item| item[:reason] }.uniq.join(", ")
      I18n.t("checkout.reorder.errors.could_not_add_items", reasons: reasons)
    else
      I18n.t("checkout.reorder.errors.unable_to_add_items")
    end
  end
end
