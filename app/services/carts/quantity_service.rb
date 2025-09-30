# frozen_string_literal: true

class Carts::QuantityService
  MAX_QUANTITY = 99

  def self.validate_quantity(quantity, product_variant: nil, existing_quantity: 0)
    new.validate_quantity(quantity, product_variant: product_variant, existing_quantity: existing_quantity)
  end

  def self.can_increment?(cart_item)
    new.validate_quantity(1, product_variant: cart_item.product_variant, existing_quantity: cart_item.quantity)
  end

  def self.can_set_quantity?(cart_item, new_quantity)
    new.validate_set_quantity(cart_item, new_quantity)
  end

  def validate_quantity(quantity, product_variant: nil, existing_quantity: 0)
    errors = []
    quantity = quantity.to_i

    if quantity <= 0
      errors << I18n.t("services.quantity.must_be_positive")
    elsif quantity > MAX_QUANTITY
      errors << I18n.t("services.quantity.exceeds_maximum", max: MAX_QUANTITY)
    end

    if product_variant
      unless product_variant.in_stock?
        errors << I18n.t("services.quantity.out_of_stock",
                          product_name: product_variant.product.name,
                          variant_name: product_variant.name)
      end

      final_quantity = existing_quantity + quantity
      if final_quantity > MAX_QUANTITY
        errors << I18n.t("services.quantity.cannot_add_more", max: MAX_QUANTITY)
      elsif product_variant.stock_quantity < final_quantity
        available = product_variant.stock_quantity - existing_quantity
        if available <= 0
          errors << I18n.t("services.quantity.no_more_available",
                            product_name: product_variant.product.name,
                            variant_name: product_variant.name)
        else
          errors << I18n.t("services.quantity.only_more_available",
                            available: available,
                            product_name: product_variant.product.name,
                            variant_name: product_variant.name)
        end
      end
    end

    if errors.empty?
      BaseResult.new(resource: quantity, success: true)
    else
      BaseResult.new(errors: errors, success: false)
    end
  end

  def validate_set_quantity(cart_item, new_quantity)
    errors = []
    new_quantity = new_quantity.to_i

    if new_quantity < 0
      errors << I18n.t("services.quantity.cannot_be_negative")
    elsif new_quantity > MAX_QUANTITY
      errors << I18n.t("services.quantity.exceeds_maximum", max: MAX_QUANTITY)
    end

    if new_quantity > 0 && cart_item.product_variant
      unless cart_item.product_variant.in_stock?
        errors << I18n.t("services.quantity.out_of_stock",
                          product_name: cart_item.product_variant.product.name,
                          variant_name: cart_item.product_variant.name)
      end

      if cart_item.product_variant.stock_quantity < new_quantity
        errors << I18n.t("services.quantity.only_available",
                          available: cart_item.product_variant.stock_quantity)
      end
    end

    if errors.empty?
      BaseResult.new(resource: new_quantity, success: true)
    else
      BaseResult.new(errors: errors, success: false)
    end
  end
end
