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
    @log_queue = []
  end

  def call
    return success_result unless should_merge?

    ActiveRecord::Base.transaction do
      merge_cart_items
      deactivate_guest_cart
    end

    execute_queued_logs
    success_result
  rescue => e
    Rails.logger.error "Carts::MergeService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @errors << "We couldn't merge your cart items. Please try again."
    failure_result
  end

  private

  attr_reader :user_cart, :guest_cart, :errors, :merged_items_count, :log_queue

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
    user_items_by_variant_id = user_cart.cart_items.includes(:product_variant).index_by(&:product_variant_id)

    guest_cart.cart_items.includes(:product_variant).each do |guest_item|
      merge_cart_item(guest_item, user_items_by_variant_id)
    end
  end

  def merge_cart_item(guest_item, user_items_by_variant_id)
    existing_item = user_items_by_variant_id[guest_item.product_variant_id]

    if existing_item
      new_quantity = existing_item.quantity + guest_item.quantity
      result = Carts::ItemUpdateService.set_quantity(existing_item, new_quantity)

      if result.success?
        @merged_items_count += 1
        queue_log(:info, "Successfully merged #{guest_item.quantity} items of #{guest_item.product_variant.name} into existing cart item")
      else
        Rails.logger.warn "Carts::MergeService: Failed to merge item #{guest_item.product_variant.name}: #{result.errors.join(', ')}"
        @errors.concat(result.errors)
      end
    else
      guest_item.update!(cart: user_cart)
      @merged_items_count += 1
      queue_log(:info, "Successfully moved item #{guest_item.product_variant.name} to user cart")
    end
  end

  def deactivate_guest_cart
    guest_cart.mark_as_abandoned!
    queue_log(:info, "Successfully marked guest cart #{guest_cart.session_token} as abandoned")
  end

  def queue_log(level, message)
    @log_queue << { level: level, message: "Carts::MergeService: #{message}" }
  end

  def execute_queued_logs
    @log_queue.each do |log_entry|
      Rails.logger.public_send(log_entry[:level], log_entry[:message])
    end
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
