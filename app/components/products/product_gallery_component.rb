# frozen_string_literal: true

class Products::ProductGalleryComponent < ViewComponent::Base
  include DiscountBadgeHelper

  MAX_VISIBLE_THUMBNAILS = 4
  THUMBNAIL_SIZE = { width: 68, height: 68, spacing: 8 }.freeze

  def initialize(product:, selected_variant: nil)
    @product = product
    @selected_variant = selected_variant
  end

  def image_url(attachment, size: :large)
    gallery_image = Products::GalleryImage.new(
      attachment: attachment,
      type: attachment ? :gallery : :placeholder
    )
    gallery_image.url(size)
  end

  private

  attr_reader :product, :selected_variant

  def gallery_images
    @gallery_images ||= begin
      images = build_variant_images
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

  def build_variant_images
    images = []

    # If a specific variant is selected, show only its images
    if selected_variant
      variant = selected_variant

      # Add featured image if present
      if variant.featured_image.attached?
        images << Products::GalleryImage.new(
          attachment: variant.featured_image,
          type: :variant,
          alt: "#{product.name} - #{variant.name}",
          variant_id: variant.id
        )
      end

      # Add additional images if present
      if variant.images.attached?
        variant.images.each_with_index do |image, index|
          next if variant.featured_image.attached? && image == variant.featured_image

          images << Products::GalleryImage.new(
            attachment: image,
            type: :variant,
            alt: "#{product.name} - #{variant.name} - Image #{index + 2}",
            variant_id: variant.id
          )
        end
      end
    else
      # Fallback: show default variant's images, or first variant's images
      default_variant = product.default_variant || product.product_variants.first

      if default_variant
        # Add featured image if present
        if default_variant.featured_image.attached?
          images << Products::GalleryImage.new(
            attachment: default_variant.featured_image,
            type: :variant,
            alt: "#{product.name} - #{default_variant.name}",
            variant_id: default_variant.id
          )
        end

        # Add additional images if present
        if default_variant.images.attached?
          default_variant.images.each_with_index do |image, index|
            next if default_variant.featured_image.attached? && image == default_variant.featured_image

            images << Products::GalleryImage.new(
              attachment: image,
              type: :variant,
              alt: "#{product.name} - #{default_variant.name} - Image #{index + 2}",
              variant_id: default_variant.id
            )
          end
        end
      end
    end

    images
  end

  def deduplicate_images(images)
    images.uniq
  end
end
