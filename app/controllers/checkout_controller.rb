class CheckoutController < ApplicationController
  allow_unauthenticated_access

  before_action :ensure_cart_has_items, only: [ :new, :create ]
  before_action :set_order, only: [ :show ]
  before_action :store_form_state, only: [ :create ]

  def new
    @checkout_form = CheckoutForm.new
    @cart = current_cart
  end

  def create
    @checkout_form = CheckoutForm.new(checkout_params)
    @cart = current_cart

    if @checkout_form.valid?
      result = Orders::CreateService.call(cart: @cart, customer_info: @checkout_form.to_h)

      if result.success?
        clear_cart_result = clear_cart
        session.delete(:checkout_form_data)
        if clear_cart_result.success?
          redirect_to checkout_confirmation_path(result.resource.number), notice: t("checkout.order_placed_successfully")
        else
          Rails.logger.error "Failed to clear cart after order creation: #{clear_cart_result.errors.join(', ')}"
          redirect_to checkout_confirmation_path(result.resource.number), notice: t("checkout.order_placed_successfully")
        end
      else
        flash.now[:alert] = result.errors.join(", ")
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Order confirmation page
  end

  def delivery_schedule
    @delivery_method = validated_delivery_method
    @checkout_form = CheckoutForm.new(session[:checkout_form_data] || {})

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def checkout_params
    params.require(:checkout_form).permit(
      :email, :phone_number, :first_name, :last_name,
      :address_line_1, :address_line_2, :city, :landmarks,
      :delivery_method, :payment_method, :delivery_notes,
      :delivery_date, :delivery_time_slot
    )
  end

  def ensure_cart_has_items
    if current_cart.nil? || current_cart.cart_items.empty?
      redirect_to cart_path, alert: t("checkout.cart_empty")
    end
  end

  def set_order
    @order = Order.find_by!(number: params[:id])
  end

  def store_form_state
    if params[:checkout_form].present?
      session[:checkout_form_data] = checkout_params.to_h
    end
  end

  def validated_delivery_method
    delivery_method = params[:delivery_method]
    %w[courier pickup].include?(delivery_method) ? delivery_method : "pickup"
  end

  def clear_cart
    return BaseResult.new(success: true) unless current_cart

    Carts::ClearService.call(cart: current_cart)
  end
end
