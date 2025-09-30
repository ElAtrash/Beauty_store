# frozen_string_literal: true

class CartItemsController < ApplicationController
  allow_unauthenticated_access
  include HeaderHelper

  before_action :ensure_cart_exists, only: [ :create ]
  before_action :set_cart_item, only: [ :update, :destroy ]

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

      sync_result = Carts::SyncService.call(
        cart: @cart,
        notification: {
          type: "success",
          message: I18n.t("cart_items.messages.added_successfully"),
          cart_item: @cart_item,
          delay: 3000
        },
        variant: @product_variant
      )

      render_cart_response(sync_result)
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

  def update
    @product = @cart_item.product_variant.product

    result = Carts::ItemUpdateService.call(@cart_item, params: params)

    if result.success?
      @cart = result.cart

      sync_result = Carts::SyncService.call(
        cart: @cart,
        variant: @cart_item.product_variant
      )

      render_cart_response(sync_result)
    else
      respond_with_error(result.errors.join(", "))
    end
  end

  def destroy
    @product = @cart_item.product_variant.product
    variant = @cart_item.product_variant

    result = Carts::ItemUpdateService.set_quantity(@cart_item, 0)

    if result.success?
      @cart = result.cart
      sync_result = Carts::SyncService.call(cart: @cart, variant: variant)
      render_cart_response(sync_result)
    else
      respond_with_error(result.errors.join(", "))
    end
  end

  def clear_all
    @cart = current_cart

    result = Carts::ClearService.call(cart: @cart)

    if result.success?
      sync_result = Carts::SyncService.call(
        cart: result.cart,
        notification: { type: "success", message: I18n.t("cart_items.messages.cleared_successfully"), delay: 2000 },
        cleared_variants: result.cleared_variants
      )

      render_cart_response(sync_result)
    else
      respond_with_error(result.errors.join(", "))
    end
  end

  private

  def ensure_cart_exists
    unless current_cart
      result = Carts::FindOrCreateService.call(
        user: Current.user,
        session: session,
        cart_token: session[:cart_token]
      )

      if result.success?
        @cart = result.cart
      else
        redirect_to root_path, alert: I18n.t("cart_items.messages.cart_unavailable")
        throw :abort
      end
    end
  end

  def set_cart_item
    @cart_item = CartItem.find(params[:id])

    # Verify the cart item belongs to the current session/user
    unless cart_item_accessible?(@cart_item)
      respond_with_not_found
      throw :abort
    end
  rescue ActiveRecord::RecordNotFound
    respond_with_not_found
    throw :abort
  end

  def cart_item_accessible?(cart_item)
    # Allow access if it belongs to current cart
    return true if cart_item.cart == current_cart

    # Allow access if user is authenticated and owns the cart
    return true if Current.user && cart_item.cart.user == Current.user

    # Allow access if it's the same session (session_token matches)
    return true if session[:cart_token] && cart_item.cart.session_token == session[:cart_token]

    false
  end

  def respond_with_error(message, error_type: :generic)
    @error_message = message
    @cart = @cart_item&.cart || current_cart

    respond_to do |format|
      case error_type
      when :not_found
        format.html { redirect_to cart_path, alert: message }
        format.turbo_stream { render "cart_items/not_found" }
      else
        format.html { redirect_back(fallback_location: cart_path, alert: message) }
        format.turbo_stream { render "cart_items/error" }
      end
      format.json { render json: { success: false, errors: [ message ] } }
    end
  end

  def respond_with_not_found
    respond_with_error(I18n.t("cart_items.messages.not_found"), error_type: :not_found)
  end


  def render_cart_response(sync_result)
    respond_to do |format|
      format.html { redirect_to cart_path, notice: sync_result.notification&.[](:message) }
      format.turbo_stream do
        render "shared/cart_sync", locals: {
          cart: sync_result.cart,
          variant: sync_result.variant,
          cleared_variants: sync_result.cleared_variants,
          notification: sync_result.notification
        }
      end
      format.json { render json: { success: true, cart_summary: sync_result.cart_summary_data } }
    end
  end
end
