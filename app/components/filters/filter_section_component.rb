# frozen_string_literal: true

class Filters::FilterSectionComponent < ViewComponent::Base
  def initialize(section_id:, title:, options:, filter_type:, selected_values: [], controller_name:)
    @section_id = section_id
    @title = title
    @options = options
    @filter_type = filter_type
    @selected_values = Array(selected_values)
    @controller_name = controller_name
  end

  private

  attr_reader :section_id, :title, :options, :filter_type, :selected_values, :controller_name

  def has_options?
    options.any?
  end

  def section_data_attributes
    {
      action: "click->#{controller_name}#toggleSection",
      section: section_id
    }
  end
end
