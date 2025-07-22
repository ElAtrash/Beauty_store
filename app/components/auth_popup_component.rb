# frozen_string_literal: true

class AuthPopupComponent < ViewComponent::Base
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
        icon: render(IconComponent.new(name: :profile, class: "w-5 h-5")),
        text: t("auth.profile"),
        path: "#"
      },
      {
        icon: render(IconComponent.new(name: :orders, class: "w-5 h-5")),
        text: t("auth.orders"),
        path: "#"
      },
      {
        icon: render(IconComponent.new(name: :settings, class: "w-5 h-5")),
        text: t("auth.settings"),
        path: "#"
      }
    ]
  end
end
