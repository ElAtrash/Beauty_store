# frozen_string_literal: true

class IconComponent < ViewComponent::Base
  include IconPath

  FILL_ICONS = %i[check_circle exclamation_circle chevron_right star].freeze
  HEROICONS_VIEWBOX = "0 0 20 20"
  DEFAULT_VIEWBOX = "0 0 24 24"

  def initialize(name:, css_class: nil, class: nil, aria_label: nil, **attrs)
    @name = name.to_sym
    # Support both class: and css_class: for backward compatibility
    @css_class = css_class || binding.local_variable_get(:class)
    @aria_label = aria_label
    @attrs = attrs

    raise ArgumentError, "Unknown icon: #{@name}" unless IconPath::ICONS.key?(@name)
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

    # Configure fill and stroke based on icon type
    if FILL_ICONS.include?(name)
      base_attrs[:fill] = "currentColor"
    elsif name == :loading
      base_attrs[:fill] = "none"
      base_attrs[:xmlns] = "http://www.w3.org/2000/svg"
    else
      base_attrs[:fill] = "none"
      base_attrs[:stroke] = "currentColor"
    end

    # Accessibility attributes
    base_attrs[:"aria-hidden"] = "true" unless aria_label
    base_attrs[:"aria-label"] = aria_label if aria_label

    base_attrs.merge(attrs)
  end
end
