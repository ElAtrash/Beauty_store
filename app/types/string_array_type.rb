# frozen_string_literal: true

# Custom attribute type for handling string arrays in ActiveModel forms
# Converts various input formats into clean string arrays
class StringArrayType < ActiveModel::Type::Value
  def cast(value)
    case value
    when Array then value.map(&:to_s).reject(&:blank?)
    when String then value.split(",").map(&:strip).reject(&:blank?)
    when nil then []
    else
      [ value.to_s ].reject(&:blank?)
    end
  end

  def serialize(value)
    cast(value)
  end
end
