# frozen_string_literal: true

module Products
  GalleryImage = Struct.new(:attachment, :type, :alt, :variant_id, keyword_init: true) do
    def attached?
      attachment.present?
    end

    def safe_alt
      alt.presence || "Product image"
    end

    def ==(other)
      return false unless other.is_a?(GalleryImage)
      return true if type == :placeholder && other.type == :placeholder
      return false if type == :placeholder || other.type == :placeholder

      attachment == other.attachment
    end

    alias_method :eql?, :==

    def hash
      return "placeholder".hash if type == :placeholder
      attachment&.id&.hash || 0
    end
  end
end
