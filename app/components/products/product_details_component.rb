# frozen_string_literal: true

class Products::ProductDetailsComponent < ViewComponent::Base
  def initialize(attributes:)
    @attributes = attributes
  end

  private

  attr_reader :attributes

  def display_attributes
    @display_attributes ||= attributes.select { |attr| attr[:value].present? }
  end

  def has_attributes?
    display_attributes.any?
  end
end
