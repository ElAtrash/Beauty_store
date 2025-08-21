# frozen_string_literal: true

class FormComponent < BaseComponent
  private

  def form_input_classes(error: false, **additional)
    base_classes = %w[form-input]
    error_classes = error ? %w[border-red-500 focus:border-red-500 focus:ring-red-500] : %w[border-gray-300]

    css_classes(base_classes, error_classes, additional[:class])
  end

  def form_label_classes(**additional)
    css_classes("block text-sm font-medium text-secondary mb-1", additional[:class])
  end

  def form_error_classes(**additional)
    css_classes("text-red-600 text-xs mt-1 hidden field-error", additional[:class])
  end

  def field_has_error?(field_name, errors)
    errors&.key?(field_name.to_sym) || false
  end

  def field_error_message(field_name, errors)
    return nil unless field_has_error?(field_name, errors)

    error_list = errors[field_name.to_sym]
    Array(error_list).first
  end
end
