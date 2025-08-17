# frozen_string_literal: true

class ProductAttributeService
  ATTRIBUTE_DISPLAY = {
    hair_type: { display_name: "Hair Type", type: :array },
    suitable_for: { display_name: "Suitable For", type: :array },
    intended_for: { display_name: "Intended For", type: :array },
    skin_type: { display_name: "Skin Type", type: :array },
    application_area: { display_name: "Application Area" },
    texture: { display_name: "Texture" },
    finish: { display_name: "Finish" },
    spf: { display_name: "SPF Protection" },
    material: { display_name: "Material" },
    fragrance_family: { display_name: "Fragrance Family" },
    sillage: { display_name: "Sillage" },
    longevity: { display_name: "Longevity" },
    water_resistant: { display_name: "Water Resistant" },
    sulfate_free: { display_name: "Sulfate Free" },
    paraben_free: { display_name: "Paraben Free" },
    alcohol_free: { display_name: "Alcohol Free" },
    cruelty_free: { display_name: "Cruelty Free" }
  }.freeze

  class << self
    def format_for_display(product)
      return [] unless product.present?

      attributes = []

      attributes << {
        label: "Product Type",
        value: product.product_type&.humanize || "Unknown",
        key: "product_type"
      }

      product.product_attributes.each do |key, value|
        next if value.blank?

        config = ATTRIBUTE_DISPLAY[key.to_sym]
        display_name = config&.dig(:display_name) || key.humanize
        type = config&.dig(:type) || detect_type(value)

        formatted_value = format_value(value, type)
        next if formatted_value.blank?

        attributes << {
          label: display_name,
          value: formatted_value,
          key: key
        }
      end

      attributes.compact
    end

    def initialize_product_attributes(product)
      if product.product_attributes.nil?
        product.product_attributes = {}
        product.save if product.persisted?
      end
    end

    private

    def detect_type(value)
      case value
      when Array then :array
      else :string
      end
    end

    def format_value(value, type)
      case type
      when :array, "array"
        return nil if value.blank?
        Array(value).reject(&:blank?).join(", ")
      else
        value.present? ? value.to_s : nil
      end
    end
  end
end
