# frozen_string_literal: true

class CartsController < ApplicationController
  allow_unauthenticated_access

  before_action :set_cart, only: [ :show, :destroy ]

  def show
    @cart_items = @cart.cart_items.includes(product_variant: [ :product, :brand ])

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def summary
    @cart = current_cart
    @cart_summary = {
      total_quantity: @cart&.total_quantity || 0,
      total_price: @cart&.formatted_total || Money.new(0, "USD").format,
      items_count: @cart&.cart_items&.count || 0
    }

    respond_to do |format|
      format.json { render json: @cart_summary }
      format.turbo_stream { render "carts/summary" }
    end
  end

  def destroy
    @cart&.cart_items&.destroy_all
    @cart&.destroy

    session.delete(:cart_id)

    respond_to do |format|
      format.html { redirect_to root_path, notice: "Cart cleared successfully" }
      format.turbo_stream { render "carts/cleared" }
    end
  end

  private

  def set_cart
    @cart = current_cart

    unless @cart
      respond_to do |format|
        format.html { redirect_to root_path, alert: "No active cart found" }
        format.turbo_stream { render "carts/not_found" }
      end
    end
  end
end
