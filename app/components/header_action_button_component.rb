# frozen_string_literal: true

class HeaderActionButtonComponent < ViewComponent::Base
  def initialize(icon:, action:, aria_label:, badge: nil)
    @icon = icon
    @action = action
    @aria_label = aria_label
    @badge = badge
  end

  private

  attr_reader :icon, :action, :aria_label, :badge

  def has_badge?
    badge && badge > 0
  end

  def badge_aria_label
    I18n.t("header.badge_count", count: badge) if has_badge?
  end
end
