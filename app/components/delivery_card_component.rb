# frozen_string_literal: true

class DeliveryCardComponent < ViewComponent::Base
  attr_reader :icon, :title, :subtitle, :variant, :action, :status, :css_class

  def initialize(icon:, title:, subtitle:, variant: :default, action: nil, status: nil, css_class: nil)
    @icon = icon
    @title = title
    @subtitle = subtitle
    @variant = variant
    @action = action
    @status = status
    @css_class = css_class
  end

  private

  def card_classes
    class_names(
      "delivery-card btn-icon",
      variant_classes,
      status_classes,
      css_class
    )
  end

  def variant_classes
    case variant
    when :pickup
      "delivery-card--pickup"
    when :address
      "delivery-card--address"
    when :confirmed
      "delivery-card--confirmed"
    else
      ""
    end
  end

  def status_classes
    case status
    when :selected
      "selected"
    when :disabled
      "disabled"
    else
      ""
    end
  end

  def has_action?
    action.present?
  end

  def action_text
    action[:text] if has_action?
  end

  def action_url
    action[:url] if has_action?
  end

  def action_attributes
    return {} unless has_action?

    attributes = {}
    attributes[:href] = action_url if action_url
    attributes[:'data-action'] = action[:data_action] if action[:data_action]
    attributes[:class] = "delivery-details-button"
    attributes[:'aria-label'] = action[:aria_label] if action[:aria_label]
    attributes
  end
end
