# frozen_string_literal: true

class AlphabetNavigationComponent < ViewComponent::Base
  def initialize(navigation_items:, selected_letter: nil)
    @navigation_items = navigation_items
    @selected_letter = selected_letter
  end

  private

  attr_reader :navigation_items, :selected_letter

  def brands_path
    Rails.application.routes.url_helpers.brands_path
  end
end
