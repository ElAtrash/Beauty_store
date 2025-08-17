# frozen_string_literal: true

class Products::GalleryModalComponent < ViewComponent::Base
  THUMBNAIL_SIZE = { width: 72, height: 72, spacing: 12 }.freeze
  MAX_VISIBLE_THUMBNAILS = 4

  def initialize(product:, gallery_images:, current_image_index: 0)
    @product = product
    @gallery_images = gallery_images
    @current_image_index = current_image_index
  end

  def image_url(attachment, size: :large)
    return placeholder_url if attachment.nil?

    if attachment.content_type == "image/svg+xml"
      return Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
    end

    variant_params = image_variants[size] || image_variants[:medium]

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

  def thumbnail_container_height
    visible_count = [ gallery_images.size, MAX_VISIBLE_THUMBNAILS ].min
    visible_count * THUMBNAIL_SIZE[:height] + (visible_count - 1) * THUMBNAIL_SIZE[:spacing]
  end

  def show_thumbnail_arrows?
    gallery_images.size > MAX_VISIBLE_THUMBNAILS
  end

  private

  attr_reader :product, :gallery_images, :current_image_index

  def image_variants
    {
      large: { resize_to_fill: [ 800, 600, { gravity: :center } ] },
      thumbnail: { resize_to_fill: [ 100, 100, { gravity: :center } ] },
      medium: { resize_to_fill: [ 400, 300, { gravity: :center } ] }
    }.freeze
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
end
