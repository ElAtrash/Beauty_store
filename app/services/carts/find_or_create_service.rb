# frozen_string_literal: true

class Carts::FindOrCreateService
  def self.call(user: nil, session: nil, cart_token: nil)
    new(user: user, session: session, cart_token: cart_token).call
  end

  def initialize(user: nil, session: nil, cart_token: nil)
    @user = user
    @session = session
    @cart_token = cart_token
  end

  def call
    cart = find_existing_cart || create_new_cart
    cart = merge_guest_cart_if_needed(cart)
    update_session(cart) if @session

    BaseResult.new(
      success: true,
      resource: cart,
      cart: cart
    )
  rescue => e
    Rails.logger.error "Cart creation failed: #{e.message}"
    BaseResult.new(
      success: false,
      errors: [ "Unable to create cart" ]
    )
  end

  private

  attr_reader :user, :session, :cart_token

  def find_existing_cart
    if user
      user_cart = Cart.active.find_by(user: user)
      return user_cart if user_cart
    end

    if cart_token.present?
      Cart.active.find_by(session_token: cart_token)
    end
  end

  def create_new_cart
    cart_attributes = { user: user }
    Cart.create!(cart_attributes)
  end

  def merge_guest_cart_if_needed(cart)
    return cart unless should_attempt_merge?(cart)

    guest_cart = find_guest_cart
    return cart unless guest_cart

    merge_result = Carts::MergeService.call(user_cart: cart, guest_cart: guest_cart)

    if merge_result.success? && merge_result.merged_any_items?
      Rails.logger.info "Carts::FindOrCreateService: Successfully merged #{merge_result.merged_items_count} items from guest cart"
    elsif merge_result.failure?
      Rails.logger.warn "Carts::FindOrCreateService: Cart merge failed: #{merge_result.errors.join(', ')}"
    end

    merge_result.cart || cart
  end

  def should_attempt_merge?(cart)
    user.present? && cart_token.present? && cart&.user == user
  end

  def find_guest_cart
    return nil unless cart_token.present?

    guest_cart = Cart.active.find_by(session_token: cart_token)

    guest_cart&.user.nil? ? guest_cart : nil
  end

  def update_session(cart)
    session[:cart_token] = cart.session_token
  end
end
