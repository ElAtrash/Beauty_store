# frozen_string_literal: true

class Carts::FindOrCreateService
  include BaseService

  def self.call(user: nil, session: nil, cart_token: nil)
    new(user: user, session: session, cart_token: cart_token).call
  end

  def initialize(user: nil, session: nil, cart_token: nil)
    @user = user
    @session = session
    @cart_token = cart_token
  end

  def call
    cart = if user.present?
      find_or_create_user_cart
    else
      find_or_create_guest_cart
    end

    update_session(cart) if session
    success(resource: cart, cart: cart)
  rescue => e
    log_error("cart creation failed", e)
    failure(I18n.t("services.errors.something_went_wrong"))
  end

  private

  attr_reader :user, :session, :cart_token

  def find_or_create_user_cart
    user_cart = Cart.active.find_by(user: user)

    if user_cart
      merge_guest_cart_into_user_cart(user_cart)
      return user_cart
    end

    if cart_token.present?
      guest_cart = Cart.active.find_by(session_token: cart_token, user_id: nil)

      if guest_cart
        guest_cart.update!(user: user)
        Rails.logger.info "Carts::FindOrCreateService: Claimed guest cart #{guest_cart.id} for user #{user.id}"
        return guest_cart
      end
    end

    create_user_cart
  end

  def create_user_cart
    cart = Cart.create!(user: user)
    Rails.logger.info "Carts::FindOrCreateService: Created new cart #{cart.id} for user #{user.id}"
    cart
  end

  def merge_guest_cart_into_user_cart(user_cart)
    return unless cart_token.present?

    guest_cart = Cart.active.find_by(session_token: cart_token, user_id: nil)
    return unless guest_cart
    return if guest_cart == user_cart

    merge_result = Carts::MergeService.call(user_cart: user_cart, guest_cart: guest_cart)

    if merge_result.success? && merge_result.merged_any_items?
      Rails.logger.info "Carts::FindOrCreateService: Merged #{merge_result.merged_items_count} items from guest cart #{guest_cart.id} into user cart #{user_cart.id}"
    end
  end

  def find_or_create_guest_cart
    if cart_token.present?
      guest_cart = Cart.active.find_by(session_token: cart_token, user_id: nil)
      return guest_cart if guest_cart
    end

    create_guest_cart
  end

  def create_guest_cart
    cart = Cart.create!(user: nil)
    Rails.logger.info "Carts::FindOrCreateService: Created new guest cart #{cart.id}"
    cart
  end

  def update_session(cart)
    session[:cart_token] = cart.session_token
  end
end
