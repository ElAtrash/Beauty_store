# frozen_string_literal: true

class ProductTabComponent < ViewComponent::Base
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

  def tab_name
    section[:name]
  end

  def tab_content
    section[:content]
  end

  def tab_button_classes
    base_classes = "product-tab-button"

    if active?
      "#{base_classes} text-text-primary border-b-2 border-text-primary"
    else
      "#{base_classes} text-text-muted border-b-2 border-transparent hover:text-text-secondary"
    end
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

  def data_attributes
    {
      products_tabs_target: "tabButton",
      action: "click->products--tabs#switchTab",
      products_tabs_index_param: index
    }
  end
end
