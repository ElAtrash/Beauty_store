# frozen_string_literal: true

class UI::HeaderActionButtonComponent < ViewComponent::Base
  def initialize(icon:, action:, aria_label:, badge: nil)
    @icon = icon
    @action = action
    @aria_label = aria_label
    @badge = badge
  end

  private

  attr_reader :icon, :action, :aria_label, :badge

  def action_string
    # If action contains '#', it's a full controller#action string
    if action.include?("#")
      action
    else
      # Legacy support: prepend with navigation--header# for backward compatibility
      "navigation--header##{action}"
    end
  end

  def has_badge?
    badge && badge > 0
  end

  def badge_aria_label
    I18n.t("header.badge_count", count: badge) if has_badge?
  end
end
