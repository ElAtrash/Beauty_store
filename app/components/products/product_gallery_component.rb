# frozen_string_literal: true

class Products::ProductGalleryComponent < ViewComponent::Base
  MAX_VISIBLE_THUMBNAILS = 4
  THUMBNAIL_SIZE = { width: 68, height: 68, spacing: 8 }.freeze

  IMAGE_VARIANTS = {
    large: { resize_to_fill: [ 800, 600, { gravity: :center } ] },
    thumbnail: { resize_to_fill: [ 100, 100, { gravity: :center } ] },
    medium: { resize_to_fill: [ 400, 300, { gravity: :center } ] }
  }.freeze

  def initialize(product:, selected_variant: nil)
    @product = product
    @selected_variant = selected_variant
  end

  def image_url(attachment, size: :large)
    return placeholder_url if attachment.nil?

    if attachment.content_type == "image/svg+xml"
      return Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
    end

    variant_params = IMAGE_VARIANTS[size] || IMAGE_VARIANTS[:medium]

    begin
      Rails.application.routes.url_helpers.rails_blob_url(
        attachment.variant(variant_params),
        only_path: true
      )
    rescue => e
      Rails.logger.error "Failed to generate image variant: #{e.message}"
      Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
    end
  end

  def placeholder_url
    "data:image/svg+xml;base64,#{Base64.strict_encode64(generate_placeholder_svg)}"
  end

  private

  attr_reader :product, :selected_variant

  def gallery_images
    @gallery_images ||= begin
      images = []
      images.concat(build_featured_images)
      images.concat(build_product_gallery_images)
      images.concat(build_variant_images)
      deduplicate_images(images)
    end
  end

  def main_image
    @main_image ||= gallery_images.first || default_placeholder
  end

  def thumbnail_images
    @thumbnail_images ||= gallery_images
  end

  def default_placeholder
    Products::GalleryImage.new(
      attachment: nil,
      type: :placeholder,
      alt: "#{product.name} - No image available"
    )
  end

  def generate_placeholder_svg
    <<~SVG
      <svg width="600" height="600" xmlns="http://www.w3.org/2000/svg">
        <rect width="600" height="600" fill="#f9fafb"/>
        <rect x="250" y="250" width="100" height="100" rx="8" fill="#e5e7eb"/>
        <text x="300" y="380" font-family="Arial, sans-serif" font-size="16" fill="#9ca3af" text-anchor="middle">#{product.name.truncate(20)}</text>
      </svg>
    SVG
  end

  def thumbnail_container_height
    visible_count = [ thumbnail_images.size, MAX_VISIBLE_THUMBNAILS ].min

    visible_count * THUMBNAIL_SIZE[:height] + (visible_count - 1) * THUMBNAIL_SIZE[:spacing]
  end

  def cursor_data_url(icon_name)
    icon_path = IconPath::ICONS[icon_name]
    return "" unless icon_path

    size = icon_name == :cursor_zoom ? 40 : 36
    svg_content = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{size}" height="#{size}" fill="none" viewBox="0 0 24 24">
        #{icon_path}
      </svg>
    SVG

    "data:image/svg+xml;base64,#{Base64.strict_encode64(svg_content)}"
  end

  def responsive_thumbnail_config
    {
      max_visible: MAX_VISIBLE_THUMBNAILS,
      thumbnail_size: THUMBNAIL_SIZE,
      show_arrows: thumbnail_images.size > MAX_VISIBLE_THUMBNAILS
    }
  end

  def build_featured_images
    return [] unless product.featured_image.attached?

    [ Products::GalleryImage.new(
      attachment: product.featured_image,
      type: :featured,
      alt: "#{product.name} - Main Image"
    ) ]
  end

  def build_product_gallery_images
    images = []

    product.images.each_with_index do |image, index|
      next if product.featured_image.attached? && image == product.featured_image

      images << Products::GalleryImage.new(
        attachment: image,
        type: :gallery,
        alt: "#{product.name} - Image #{index + 2}"
      )
    end

    images
  end

  def build_variant_images
    images = []

    product.product_variants.each do |variant|
      next unless variant.featured_image.attached?

      images << Products::GalleryImage.new(
        attachment: variant.featured_image,
        type: :variant,
        alt: "#{product.name} - #{variant.name}",
        variant_id: variant.id
      )
    end

    images
  end

  def deduplicate_images(images)
    images.uniq
  end
end
