# frozen_string_literal: true

class Carts::ClearService
  def self.call(cart:)
    new(cart: cart).call
  end

  def initialize(cart:)
    @cart = cart
    @cleared_variants = []
    @cleared_items_count = 0
  end

  def call
    return Carts::BaseResult.new(
      success: true,
      cart: @cart,
      cleared_variants: [],
      cleared_items_count: 0
    ) if @cart.nil? || @cart.cart_items.empty?

    transaction_success = false
    errors = []

    begin
      ActiveRecord::Base.transaction do
        @cleared_variants = @cart.cart_items.includes(:product_variant).map(&:product_variant)
        @cleared_items_count = @cart.cart_items.count

        @cart.cart_items.find_each do |cart_item|
          result = Carts::ItemUpdateService.set_quantity(cart_item, 0)
          unless result.success?
            errors.concat(result.errors)
            raise ActiveRecord::Rollback, "Failed to clear item: #{result.errors.join(', ')}"
          end
        end

        @cart.cart_items.reload
        transaction_success = true
      end

      if transaction_success
        Carts::BaseResult.new(
          success: true,
          cart: @cart,
          cleared_variants: @cleared_variants,
          cleared_items_count: @cleared_items_count
        )
      else
        Rails.logger.error "Carts::ClearService transaction rolled back: Failed to clear items"
        Carts::BaseResult.new(
          success: false,
          cart: @cart,
          errors: errors.presence || [ "We couldn't clear your cart. Please try again." ]
        )
      end
    rescue => e
      Rails.logger.error "Carts::ClearService unexpected error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      Carts::BaseResult.new(
        success: false,
        cart: @cart,
        errors: [ "We couldn't clear your cart. Please try again." ]
      )
    end
  end

  private

  attr_reader :cart, :cleared_variants, :cleared_items_count
end
