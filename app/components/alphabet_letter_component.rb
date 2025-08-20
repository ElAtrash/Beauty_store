# frozen_string_literal: true

class AlphabetLetterComponent < ViewComponent::Base
  with_collection_parameter :item

  def initialize(item:)
    @item = item
  end

  private

  attr_reader :item

  def has_brands?
    item[:count] > 0
  end

  def letter
    item[:letter]
  end

  def count
    item[:count]
  end

  def url
    item[:url]
  end

  def active?
    item[:active]
  end

  def letter_class
    base_classes = "alphabet-letter-btn"

    if active?
      "#{base_classes} active"
    elsif has_brands?
      "#{base_classes} available"
    else
      "#{base_classes} disabled"
    end
  end

  def aria_label
    if has_brands?
      "Browse brands starting with #{letter} (#{count} brands)"
    else
      "No brands starting with #{letter}"
    end
  end

  def aria_current
    active? ? "page" : nil
  end

  def link_data_attributes
    {
      turbo_frame: "brands-content",
      brands_letter_value: letter.downcase,
      action: "keydown.enter->brands#handleKeyboardNavigation keydown.space->brands#handleKeyboardNavigation",
      brands_letter_param: letter
    }
  end
end
