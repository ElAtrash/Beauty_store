# frozen_string_literal: true

class IconComponent < ViewComponent::Base
  include IconPath

  def initialize(name:, class: nil, aria_label: nil, **attrs)
    @name = name.to_sym
    @css_class = binding.local_variable_get(:class)
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
      viewBox: "0 0 24 24"
    }

    # Special handling for icons that use fill instead of stroke
    if [ :check_circle, :exclamation_circle ].include?(name)
      base_attrs[:fill] = "currentColor"
      base_attrs[:viewBox] = "0 0 20 20"
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
