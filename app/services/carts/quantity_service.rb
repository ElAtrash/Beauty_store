# frozen_string_literal: true

class Carts::QuantityService
  MAX_QUANTITY = 99

  def self.validate_quantity(quantity, product_variant: nil, existing_quantity: 0)
    new.validate_quantity(quantity, product_variant: product_variant, existing_quantity: existing_quantity)
  end

  def self.can_increment?(cart_item)
    new.can_increment?(cart_item)
  end

  def self.can_set_quantity?(cart_item, new_quantity)
    new.can_set_quantity?(cart_item, new_quantity)
  end

  def validate_quantity(quantity, product_variant: nil, existing_quantity: 0)
    errors = []
    quantity = quantity.to_i

    if quantity <= 0
      errors << "Quantity must be greater than 0"
    elsif quantity > MAX_QUANTITY
      errors << "Quantity cannot exceed #{MAX_QUANTITY}"
    end

    if product_variant
      unless product_variant.in_stock?
        errors << "#{product_variant.product.name} - #{product_variant.name} is out of stock"
      end

      final_quantity = existing_quantity + quantity
      if final_quantity > MAX_QUANTITY
        errors << "Cannot add more items. Maximum quantity is #{MAX_QUANTITY}"
      elsif product_variant.stock_quantity < final_quantity
        available = product_variant.stock_quantity - existing_quantity
        if available <= 0
          errors << "No more items available for #{product_variant.product.name} - #{product_variant.name}"
        else
          errors << "Only #{available} more items can be added for #{product_variant.product.name} - #{product_variant.name}"
        end
      end
    end

    if errors.empty?
      Carts::BaseResult.new(resource: quantity, success: true)
    else
      Carts::BaseResult.new(errors: errors, success: false)
    end
  end

  def can_increment?(cart_item)
    validate_quantity(1,
      product_variant: cart_item.product_variant,
      existing_quantity: cart_item.quantity)
  end

  def can_set_quantity?(cart_item, new_quantity)
    errors = []
    new_quantity = new_quantity.to_i

    if new_quantity < 0
      errors << "Quantity cannot be negative"
    elsif new_quantity > MAX_QUANTITY
      errors << "Quantity cannot exceed #{MAX_QUANTITY}"
    end

    if new_quantity > 0 && cart_item.product_variant
      unless cart_item.product_variant.in_stock?
        errors << "#{cart_item.product_variant.product.name} - #{cart_item.product_variant.name} is out of stock"
      end

      if cart_item.product_variant.stock_quantity < new_quantity
        errors << "Only #{cart_item.product_variant.stock_quantity} items available"
      end
    end

    if errors.empty?
      Carts::BaseResult.new(resource: new_quantity, success: true)
    else
      Carts::BaseResult.new(errors: errors, success: false)
    end
  end
end
