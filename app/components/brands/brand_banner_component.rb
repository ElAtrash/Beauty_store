# frozen_string_literal: true

class Brands::BrandBannerComponent < ViewComponent::Base
  delegate :name, :description, :banner_image, to: :brand

  def initialize(brand:)
    @brand = brand
  end

  private

  attr_reader :brand

  def banner_image?
    @banner_image_present ||= banner_image.attached?
  end

  def banner_classes
    base_classes = "relative flex h-72 items-center justify-center overflow-hidden md:h-80"

    variant_classes = if banner_image?
      "bg-cover bg-center bg-no-repeat bg-fixed"
    else
      "bg-gradient-to-r from-gray-50 to-gray-100"
    end

    "#{base_classes} #{variant_classes}"
  end

  def banner_style
    return "" unless banner_image?

    image_url = Rails.application.routes.url_helpers.url_for(banner_image)
    "background-image: url('#{image_url}');"
  end

  def brand_name_classes
    text_color = banner_image? ? "text-white drop-shadow-lg" : "text-gray-900"
    "hero-title #{text_color}"
  end

  def description_classes
    text_color = banner_image? ? "text-white/90" : "text-gray-600"
    "hero-subtitle #{text_color}"
  end

  def description?
    description.present?
  end
end
