# frozen_string_literal: true

class UI::IconComponent < ViewComponent::Base
  include IconPath

  FILL_ICONS = %i[check_circle exclamation_circle chevron_right star].freeze
  HEROICONS_VIEWBOX = "0 0 20 20"
  DEFAULT_VIEWBOX = "0 0 24 24"

  def initialize(name:, css_class: nil, aria_label: nil, **attrs)
    @name = name.to_sym
    @css_class = css_class
    @aria_label = aria_label
    @attrs = attrs

    raise ArgumentError, "Unknown icon: #{@name}" unless IconPath::ICONS.key?(@name)
    raise ArgumentError, "Use css_class: instead of class: parameter" if attrs.key?(:class)
  end

  private

  attr_reader :name, :css_class, :aria_label, :attrs

  def icon_path
    IconPath::ICONS[name]
  end

  def svg_attributes
    base_attrs = {
      class: css_class,
      viewBox: FILL_ICONS.include?(name) ? HEROICONS_VIEWBOX : DEFAULT_VIEWBOX
    }

    if FILL_ICONS.include?(name)
      base_attrs[:fill] = "currentColor"
    elsif name == :loading
      base_attrs[:fill] = "none"
      base_attrs[:xmlns] = "http://www.w3.org/2000/svg"
    else
      base_attrs[:fill] = "none"
      base_attrs[:stroke] = "currentColor"
    end

    base_attrs[:"aria-hidden"] = "true" unless aria_label
    base_attrs[:"aria-label"] = aria_label if aria_label

    base_attrs.merge(attrs)
  end
end
