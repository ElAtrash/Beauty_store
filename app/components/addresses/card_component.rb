# frozen_string_literal: true

class Addresses::CardComponent < ViewComponent::Base
  attr_reader :address, :show_actions

  def initialize(address:, show_actions: true)
    @address = address
    @show_actions = show_actions
  end

  private

  def card_classes
    class_names(
      "bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:shadow-md transition-shadow",
      "relative" => address.default?
    )
  end

  def address_id
    "address-#{address.id}"
  end

  def default_badge
    return unless address.default?

    content_tag(:span, t("addresses.default_badge"),
                class: "absolute top-2 right-2 px-2 py-1 text-xs font-semibold bg-primary-100 text-primary-700 rounded-full")
  end

  def address_label
    content_tag(:h3, address.display_label, class: "text-lg font-semibold text-gray-900 mb-2")
  end

  def address_lines
    [
      address.address_line_1,
      address.address_line_2,
      address.city,
      address.governorate
    ].compact.join(", ")
  end

  def landmarks_display
    return unless address.landmarks.present?

    content_tag(:p, class: "text-sm text-gray-600 mt-1") do
      concat content_tag(:span, "📍 ", class: "inline-block mr-1")
      concat address.landmarks
    end
  end

  def phone_display
    return unless address.phone_number.present?

    content_tag(:p, class: "text-sm text-gray-600 mt-1") do
      concat content_tag(:span, "📞 ", class: "inline-block mr-1")
      concat address.phone_number
    end
  end

  def actions_buttons
    return unless show_actions

    content_tag(:div, class: "flex items-center gap-2 mt-4 pt-4 border-t border-gray-100") do
      concat set_default_button unless address.default?
      concat edit_button
      concat delete_button
    end
  end

  def set_default_button
    button_to t("addresses.set_as_default"),
              set_default_address_path(address),
              method: :patch,
              data: { turbo_stream: true },
              class: "text-sm font-medium text-primary-600 hover:text-primary-700"
  end

  def edit_button
    link_to edit_address_path(address),
            data: { turbo_frame: address_id },
            class: "text-sm font-medium text-gray-600 hover:text-gray-900" do
      concat render(UI::IconComponent.new(name: :pencil, css_class: "w-4 h-4 inline-block mr-1"))
      concat t("addresses.edit_address")
    end
  end

  def delete_button
    button_to address_path(address),
              method: :delete,
              data: {
                turbo_stream: true,
                turbo_confirm: t("addresses.confirm_delete")
              },
              class: "text-sm font-medium text-red-600 hover:text-red-700" do
      concat render(UI::IconComponent.new(name: :trash, css_class: "w-4 h-4 inline-block mr-1"))
      concat t("addresses.delete_address")
    end
  end
end
