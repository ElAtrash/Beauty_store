# frozen_string_literal: true

module DiscountBadgeHelper
  # Generate discount badge text for a variant
  # @param variant [ProductVariant] The product variant
  # @param format [Symbol] The format style (:percentage, :text, :short)
  # @return [String] Formatted discount text
  def discount_badge_text(variant, format: :percentage)
    return nil unless variant&.on_sale?

    percentage = variant.discount_percentage
    return nil if percentage <= 0

    case format
    when :percentage
      "#{percentage}%"
    when :text
      "#{percentage}% off"
    when :short
      percentage.to_s
    else
      "#{percentage}%"
    end
  end

  # Generate discount badge HTML with consistent styling
  # @param variant [ProductVariant] The product variant
  # @param css_class [String] Additional CSS classes
  # @param format [Symbol] The format style
  # @return [String] HTML string for the discount badge
  def discount_badge_html(variant, css_class: nil, format: :percentage)
    return nil unless variant&.on_sale?

    text = discount_badge_text(variant, format: format)
    return nil unless text

    default_classes = "bg-pink-600 text-white text-xs font-bold"
    classes = css_class ? "#{default_classes} #{css_class}" : "#{default_classes} p-1"

    content_tag :span, text, class: classes
  end

  # Check if variant should show discount badge
  # @param variant [ProductVariant] The product variant
  # @return [Boolean]
  def show_discount_badge?(variant)
    variant&.on_sale? && variant.discount_percentage > 0
  end

  # Get discount badge data for product cards
  # @param variant [ProductVariant] The product variant
  # @return [Hash] Badge data with text and classes
  def discount_badge_data(variant)
    return nil unless show_discount_badge?(variant)

    {
      text: discount_badge_text(variant),
      classes: "bg-pink-600 text-white text-xs font-bold p-1"
    }
  end
end
