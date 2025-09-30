# frozen_string_literal: true

class Modal::AuthComponent < Modal::BaseComponent
  def initialize(current_user: nil)
    @current_user = current_user
    super(
      id: "auth",
      title: "",
      size: :medium,
      position: :right
    )
  end

  private

  attr_reader :current_user

  def content
    if signed_in?
      render "modal/auth/user_menu",
             current_user: current_user,
             user_menu_items: user_menu_items
    else
      render "modal/auth/login_form",
             eye_icon_path: eye_icon_path,
             eye_off_icon_path: eye_off_icon_path
    end
  end

  def signed_in?
    current_user.present?
  end

  def user_menu_items
    [
      {
        icon: render(UI::IconComponent.new(name: :profile, css_class: "w-5 h-5 text-gray-600")),
        text: t("auth.profile"),
        path: "#"
      },
      {
        icon: render(UI::IconComponent.new(name: :orders, css_class: "w-5 h-5 text-gray-600")),
        text: t("auth.orders"),
        path: "#"
      },
      {
        icon: render(UI::IconComponent.new(name: :settings, css_class: "w-5 h-5 text-gray-600")),
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

  def additional_data_attributes
    super.merge({
      "auth-modal-target": "modal",
      "auth-signed-in": signed_in?.to_s
    })
  end

  def container_classes
    base_classes = super
    auth_state_class = signed_in? ? "auth-modal--signed-in" : "auth-modal--signed-out"
    "#{base_classes} #{auth_state_class}"
  end
end
