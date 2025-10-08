# frozen_string_literal: true

class Addresses::SelectorCardComponent < ViewComponent::Base
  attr_reader :address, :selected, :from_checkout

  def initialize(address:, selected: false, from_checkout: false)
    @address = address
    @selected = selected
    @from_checkout = from_checkout
  end

  private

  def card_classes
    class_names(
      "delivery-card", "mb-2",
      "selected" => selected
    )
  end

  def card_id
    "address-card-#{address.id}"
  end

  def radio_button_attributes
    {
      type: "radio",
      name: "selected_address_id",
      value: address.id,
      id: "address_#{address.id}",
      checked: selected,
      class: "form-radio-input",
      data: {
        action: "change->address-selector#selectAddress",
        address_selector_target: "radioButton",
        "address-id": address.id
      }
    }
  end

  def address_title
    content_tag(:div, class: "delivery-card-title flex items-center gap-2") do
      concat address.display_label
      concat default_badge if address.default?
    end
  end

  def default_badge
    content_tag(:span, t("addresses.default_badge"),
                class: "px-2 py-0.5 text-xs font-semibold bg-primary-100 text-primary-700 rounded-full")
  end

  def address_subtitle
    address_parts = [
      address.address_line_1,
      address.address_line_2,
      address.city,
      address.governorate
    ].compact

    # Add landmarks as the last part if present
    address_parts << "Near #{address.landmarks}" if address.landmarks.present?

    content_tag(:div, address_parts.join(", "), class: "delivery-card-subtitle")
  end

  def edit_button
    link_to "#",
            data: {
              action: "click->address-selector#editAddress",
              address_id: address.id
            },
            class: "",
            title: t("addresses.edit_address"),
            aria: { label: t("addresses.edit_address") } do
      render UI::IconComponent.new(name: :pencil, css_class: "w-5 h-5 icon-interactive")
    end
  end

  def delete_button
    delete_url = from_checkout ? address_path(address, from: 'checkout') : address_path(address)

    button_to delete_url,
              method: :delete,
              data: {
                turbo_stream: true,
                turbo_confirm: t("addresses.confirm_delete")
              },
              class: "",
              title: t("addresses.delete_address"),
              aria: { label: t("addresses.delete_address") } do
      render UI::IconComponent.new(name: :close, css_class: "w-5 h-5 icon-interactive")
    end
  end
end
