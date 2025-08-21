# frozen_string_literal: true

class Filters::FilterOptionComponent < ViewComponent::Base
  with_collection_parameter :option

  def initialize(option:, filter_type:, selected_values: [], controller_name:)
    @option = option
    @filter_type = filter_type
    @selected_values = Array(selected_values)
    @controller_name = controller_name
  end

  private

  attr_reader :option, :filter_type, :selected_values, :controller_name

  def option_value
    option[:value]
  end

  def option_label
    option[:label]
  end

  def checked?
    selected_values.include?(option_value.to_s)
  end

  def input_name
    "filters[#{filter_type}][]"
  end

  def data_attributes
    {
      action: "change->#{controller_name}#updateFilter",
      filter_type: filter_type
    }
  end
end
