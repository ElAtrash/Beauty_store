# frozen_string_literal: true

class Brands::BrandDescriptionComponent < ViewComponent::Base
  def initialize(brand:)
    @brand = brand
  end

  private

  attr_reader :brand

  def has_description?
    brand.description.present?
  end

  def description
    brand.description
  end

  def long_description?
    return false unless description.present?

    description.length > 200 || description.count("\n") >= 2
  end

  def truncated_description
    return description unless long_description?

    truncated = description.truncate(200, separator: " ")

    # If the original has line breaks, truncate at the first or second line break
    lines = description.split("\n")
    if lines.length > 2
      truncated = lines[0..1].join("\n") + "..."
    end

    truncated
  end

  def brand_name
    brand.name
  end
end
