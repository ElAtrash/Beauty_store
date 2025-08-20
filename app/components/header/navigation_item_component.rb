# frozen_string_literal: true

class Header::NavigationItemComponent < ViewComponent::Base
  with_collection_parameter :item

  def initialize(item:, variant: :desktop)
    @item = item
    @variant = variant.to_sym
  end

  private

  attr_reader :item, :variant

  def desktop?
    variant == :desktop
  end

  def mobile?
    variant == :mobile
  end

  def link_classes
    base_classes = "transition-colors font-medium"

    if desktop?
      "#{base_classes} hover:text-interactive"
    else
      "block px-4 py-3 hover:bg-gray-50 transition-colors"
    end
  end

  def link_data_attributes
    if mobile?
      { action: "click->navigation--header#closeMobileMenu" }
    else
      {}
    end
  end

  def item_key
    item[:key]
  end

  def item_path
    item[:path]
  end

  def link_text
    t("header.nav.#{item_key}")
  end
end
