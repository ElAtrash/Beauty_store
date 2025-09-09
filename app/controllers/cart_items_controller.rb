# frozen_string_literal: true

class CartItemsController < ApplicationController
  allow_unauthenticated_access
  include HeaderHelper

  before_action :ensure_cart_exists, only: [ :create ]
  before_action :set_cart_item, only: [ :update, :update_quantity, :destroy ]

  def create
    @product_variant = ProductVariant.find(params[:product_variant_id])
    quantity = params[:quantity]&.to_i || 1

    result = Carts::AddItemService.call(
      cart: current_cart,
      product_variant: @product_variant,
      quantity: quantity
    )

    if result.success?
      @cart_item = result.resource
      @cart = result.cart
      @product = @product_variant.product

      render_cart_sync(
        notification: {
          type: "success",
          message: "Added to cart successfully!",
          cart_item: @cart_item,
          delay: 3000
        },
        variant: @product_variant
      )
    else
      @errors = result.errors
      @cart = result.cart

      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, alert: @errors.join(", ")) }
        format.turbo_stream { render "cart_items/error" }
        format.json { render json: { success: false, errors: @errors } }
      end
    end
  end

  def update_quantity
    @product = @cart_item.product_variant.product
    action_type, quantity_value = normalize_quantity_params

    result = case action_type
    when :increment
      Carts::ItemUpdateService.increment(@cart_item)
    when :decrement
      Carts::ItemUpdateService.decrement(@cart_item)
    when :add_more
      Carts::ItemUpdateService.add_more(@cart_item, quantity_value)
    when :set_quantity
      Carts::ItemUpdateService.set_quantity(@cart_item, quantity_value)
    end

    if result.success?
      @cart = result.cart
      render_cart_update
    else
      respond_with_error(result.errors.join(", "))
    end
  end

  def update
    redirect_to cart_path
  end

  def destroy
    @product = @cart_item.product_variant.product
    variant = @cart_item.product_variant

    result = Carts::ItemUpdateService.set_quantity(@cart_item, 0)

    if result.success?
      @cart = result.cart
      render_cart_sync(
        variant: variant
      )
    else
      respond_with_error(result.errors.join(", "))
    end
  end

  def clear_all
    @cart = current_cart

    result = Carts::ClearService.call(cart: @cart)

    if result.success?
      render_cart_sync(
        notification: { type: "success", message: "Cart cleared successfully", delay: 2000 },
        cleared_variants: result.cleared_variants
      )
    else
      respond_with_error(result.errors.join(", "))
    end
  end

  private

  def ensure_cart_exists
    unless current_cart
      @cart = Carts::FindOrCreateService.call(
        user: Current.user,
        session: session,
        cart_token: session[:cart_token]
      )
    end
  end

  def set_cart_item
    @cart_item = current_cart.cart_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to cart_path, alert: "Cart item not found" }
      format.turbo_stream { render "cart_items/not_found" }
      format.json { render json: { success: false, errors: [ "Cart item not found" ] } }
    end
  end

  def respond_with_error(message)
    @error_message = message
    @cart = @cart_item&.cart || current_cart

    respond_to do |format|
      format.html { redirect_back(fallback_location: cart_path, alert: message) }
      format.turbo_stream { render "cart_items/error" }
      format.json { render json: { success: false, errors: [ message ] } }
    end
  end

  def cart_summary_data
    cart = @cart || current_cart

    return { total_quantity: 0, total_price: "$0.00", items_count: 0 } unless cart
    {
      total_quantity: cart.total_quantity || 0,
      total_price: cart.total_price&.format || "$0.00",
      items_count: cart.cart_items.count || 0
    }
  end

  def normalize_quantity_params
    if params[:add_more].present?
      [ :add_more, params[:add_more].to_i ]
    elsif params[:quantity_action] == "increment"
      [ :increment, nil ]
    elsif params[:quantity_action] == "decrement"
      [ :decrement, nil ]
    elsif params[:quantity].present?
      [ :set_quantity, params[:quantity].to_i ]
    else
      [ :increment, nil ]
    end
  end

  def render_cart_update
    render_cart_sync(
      variant: @cart_item&.product_variant
    )
  end

  def render_cart_sync(notification: nil, variant: nil, cleared_variants: nil)
    respond_to do |format|
      format.html { redirect_to cart_path, notice: notification&.[](:message) }
      format.turbo_stream do
        render "shared/cart_sync", locals: {
          cart: @cart,
          variant: variant,
          cleared_variants: cleared_variants,
          notification: notification
        }
      end
      format.json { render json: { success: true, cart_summary: cart_summary_data } }
    end
  end
end
