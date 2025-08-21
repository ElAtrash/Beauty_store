# frozen_string_literal: true

class AuthPopupComponent < BaseComponent
  def initialize(current_user: nil)
    @current_user = current_user
  end

  private

  attr_reader :current_user

  def signed_in?
    current_user.present?
  end

  def user_menu_items
    [
      {
        icon: render(UI::IconComponent.new(name: :profile, css_class: "w-5 h-5")),
        text: t("auth.profile"),
        path: "#"
      },
      {
        icon: render(UI::IconComponent.new(name: :orders, css_class: "w-5 h-5")),
        text: t("auth.orders"),
        path: "#"
      },
      {
        icon: render(UI::IconComponent.new(name: :settings, css_class: "w-5 h-5")),
        text: t("auth.settings"),
        path: "#"
      }
    ]
  end

  def eye_icon_path
    IconPath::ICONS[:eye]
  end

  def eye_off_icon_path
    IconPath::ICONS[:eye_off]
  end
end
