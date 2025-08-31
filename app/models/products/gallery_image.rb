# frozen_string_literal: true

module Products
  class GalleryImage
    attr_reader :attachment, :type, :alt, :variant_id

    def initialize(attachment:, type:, alt: nil, variant_id: nil)
      @attachment = attachment
      @type = type
      @alt = alt
      @variant_id = variant_id
    end

    IMAGE_VARIANTS = {
      thumbnail: { resize_to_fill: [ 150, 150 ] },
      medium: { resize_to_fill: [ 400, 300 ] },
      large: { resize_to_fill: [ 800, 600 ] }
    }.freeze

    def attached? = attachment.present?
    def safe_alt  = alt.presence || "Product image"
    def placeholder? = type == :placeholder

    def url(size = :large)
      generate_url(size)
    end

    def thumbnail_url = url(:thumbnail)
    def large_url = url(:large)

    def as_json(*)
      {
        url: url,
        thumbnail_url: thumbnail_url,
        large_url: large_url,
        alt: safe_alt,
        type: type,
        variant_id: variant_id
      }
    end

    private

    def svg? = attachment&.content_type == "image/svg+xml"

    def generate_url(size)
      return placeholder_url(size) unless attached?
      return blob_url(attachment) if svg?

      variant_params = IMAGE_VARIANTS.fetch(size, IMAGE_VARIANTS[:medium])
      blob_url(attachment.variant(variant_params))
    rescue => e
      Rails.logger.error("Failed to generate image variant: #{e.message}")
      blob_url(attachment)
    end

    def blob_url(source)
      Rails.application.routes.url_helpers.rails_blob_url(source, only_path: true)
    end

    def placeholder_url(size)
      w, h = { thumbnail: [ 150, 150 ], medium: [ 400, 300 ], large: [ 800, 600 ] }.fetch(size, [ 800, 600 ])
      "data:image/svg+xml;base64,#{Base64.strict_encode64(generate_placeholder_svg(w, h))}"
    end

    def generate_placeholder_svg(width, height)
      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}" viewBox="0 0 #{width} #{height}">
          <rect width="100%" height="100%" fill="#f3f4f6"/>
          <rect x="50%" y="50%" width="2" height="2" fill="#d1d5db" transform="translate(-1,-1)"/>
        </svg>
      SVG
    end

    def ==(other)
      return false unless other.is_a?(GalleryImage)
      return type == :placeholder && other.type == :placeholder if placeholder? || other.placeholder?

      attachment == other.attachment
    end
    alias eql? ==

    def hash
      placeholder? ? "placeholder".hash : attachment&.id&.hash || 0
    end
  end
end
