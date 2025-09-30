# frozen_string_literal: true

class Checkout::ErrorResponseService
  def self.call(controller:, result:, cart:, form:)
    new(controller, result, cart, form).call
  end

  def initialize(controller, result, cart, form)
    @controller = controller
    @result = result
    @cart = cart
    @form = form
  end

  def call
    return handle_cart_redirect if cart_empty_error?

    case result.error_type
    when :validation then handle_validation_error
    when :service then handle_service_error
    else handle_generic_error
    end
  end

  private

  attr_reader :controller, :result, :cart, :form

  def cart_empty_error?
    result.errors&.any? { |error| error.include?(I18n.t("checkout.cart_empty")) }
  end

  def handle_cart_redirect
    controller.redirect_to controller.root_path, alert: result.errors.join(", ")
  end

  def handle_validation_error
    ensure_rendering_context
    return handle_cart_validation_redirect if cart_validation_failed?

    controller.flash.now[:alert] = result.errors.join(", ")
    controller.render :new, status: :unprocessable_content
  end

  def handle_service_error
    ensure_rendering_context
    return handle_cart_validation_redirect if cart_validation_failed?

    error_message = result.errors&.join(", ").presence || I18n.t("errors.something_went_wrong")
    controller.flash.now[:alert] = error_message
    controller.render :new, status: :unprocessable_content
  end

  def handle_generic_error
    handle_service_error
  end

  def ensure_rendering_context
    controller.instance_variable_set(:@cart, cart)
    controller.instance_variable_set(:@checkout_form, form)
  end

  def cart_validation_failed?
    validation_result = Checkout::CartValidationService.call(cart)
    !validation_result.success?
  end

  def handle_cart_validation_redirect
    controller.redirect_to controller.root_path, alert: I18n.t("checkout.cart_empty")
  end
end
