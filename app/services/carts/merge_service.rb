# frozen_string_literal: true

class Carts::MergeService
  def self.call(user_cart:, guest_cart:)
    new(user_cart: user_cart, guest_cart: guest_cart).call
  end

  def initialize(user_cart:, guest_cart:)
    @user_cart = user_cart
    @guest_cart = guest_cart
    @errors = []
    @merged_items_count = 0
  end

  def call
    return success_result unless should_merge?

    ActiveRecord::Base.transaction do
      merge_cart_items
      deactivate_guest_cart
    end

    success_result
  rescue => e
    Rails.logger.error "Carts::MergeService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @errors.push("We couldn't merge your cart items. Please try again.")
    failure_result
  end

  private

  attr_reader :user_cart, :guest_cart, :errors, :merged_items_count

  def should_merge?
    return false unless guest_cart&.cart_items&.any?
    return false unless user_cart

    if user_cart == guest_cart
      Rails.logger.info "Carts::MergeService: Skipping merge - same cart"
      return false
    end

    true
  end

  def merge_cart_items
    guest_cart.cart_items.includes(:product_variant).each do |guest_item|
      merge_cart_item(guest_item)
    end
  end

  def merge_cart_item(guest_item)
    existing_item ||= user_cart.cart_items.find_by(product_variant: guest_item.product_variant)

    if existing_item
      result = Carts::ItemUpdateService.add_more(existing_item, guest_item.quantity)

      if result.success?
        @merged_items_count += 1
        Rails.logger.info "Carts::MergeService: Merged #{guest_item.quantity} items of #{guest_item.product_variant.name} into existing cart item"
      else
        Rails.logger.warn "Carts::MergeService: Failed to merge item #{guest_item.product_variant.name}: #{result.errors.join(', ')}"
        @errors.concat(result.errors)
      end
    else
      guest_item.update!(cart: user_cart)
      @merged_items_count += 1
      Rails.logger.info "Carts::MergeService: Moved item #{guest_item.product_variant.name} to user cart"
    end
  end

  def deactivate_guest_cart
    guest_cart.mark_as_abandoned!
    user_cart.cart_items.reload
    Rails.logger.info "Carts::MergeService: Marked guest cart #{guest_cart.session_token} as abandoned"
  end

  def success_result
    BaseResult.new(
      cart: user_cart,
      success: true,
      merged_items_count: @merged_items_count
    )
  end

  def failure_result
    BaseResult.new(
      errors: errors,
      success: false
    )
  end
end
