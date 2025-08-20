# frozen_string_literal: true

class ProductTabPanelComponent < ViewComponent::Base
  with_collection_parameter :section_data

  def initialize(section_data:)
    @section = section_data[:section]
    @index = section_data[:index]
    @active = section_data[:active]
  end

  private

  attr_reader :section, :index, :active

  def tab_id
    section[:id]
  end

  def tab_content
    section[:content]
  end

  def tab_panel_classes
    if active?
      "product-tab-panel block"
    else
      "product-tab-panel hidden"
    end
  end

  def active?
    active
  end
end
