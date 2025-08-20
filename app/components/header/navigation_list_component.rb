# frozen_string_literal: true

class Header::NavigationListComponent < ViewComponent::Base
  def initialize(navigation_items:, variant: :desktop)
    @navigation_items = navigation_items
    @variant = variant.to_sym
  end

  private

  attr_reader :navigation_items, :variant

  def desktop?
    variant == :desktop
  end

  def mobile?
    variant == :mobile
  end

  def list_classes
    if desktop?
      "flex items-center justify-center space-x-8 py-3"
    else
      "space-y-1"
    end
  end
end
