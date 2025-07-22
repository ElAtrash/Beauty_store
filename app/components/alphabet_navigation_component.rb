# frozen_string_literal: true

class AlphabetNavigationComponent < ViewComponent::Base
  def initialize(navigation_items:, selected_letter: nil)
    @navigation_items = navigation_items
    @selected_letter = selected_letter
  end

  private

  attr_reader :navigation_items, :selected_letter

  def letter_class(item)
    base_classes = "alphabet-letter-btn"

    if item[:active]
      "#{base_classes} active"
    elsif item[:count] > 0
      "#{base_classes} available"
    else
      "#{base_classes} disabled"
    end
  end

  def brands_path
    Rails.application.routes.url_helpers.brands_path
  end
end
