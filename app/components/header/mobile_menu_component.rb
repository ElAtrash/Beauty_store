# frozen_string_literal: true

class Header::MobileMenuComponent < ViewComponent::Base
  def initialize(navigation_items:)
    @navigation_items = navigation_items
  end

  private

  attr_reader :navigation_items
end
