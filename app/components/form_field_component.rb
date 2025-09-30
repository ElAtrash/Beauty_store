# frozen_string_literal: true

class FormFieldComponent < ViewComponent::Base
  include ActionView::Helpers::TextHelper

  BASE_INPUT_CLASSES = "text-base bg-transparent focus:outline-none transition-all duration-200".freeze

  FIELD_SPECIFIC_CLASSES = {
    textarea: "w-full pl-10 pr-4 py-4 border-b border-gray-300 focus:border-gray-300 placeholder-gray-400 resize-vertical",
    tel: "w-full pl-4 pr-4 py-4 border-b border-gray-300 focus:border-gray-300 placeholder-gray-400 border-l-0",
    text: "w-full pl-10 pr-4 py-4 border-b border-gray-300 focus:border-gray-300 placeholder-gray-400"
  }.freeze

  ERROR_CLASSES = "border-red-500 focus:border-red-500".freeze

  SUBMIT_BUTTON_CLASSES = "py-3 px-4 btn-interactive btn-full btn-lg transition-colors".freeze

  PHONE_CONTAINER_CLASSES = "flex".freeze
  PHONE_PREFIX_BASE_CLASSES = "flex items-center pl-10 pr-3 text-base text-gray-700 border-b border-r-0".freeze
  PHONE_PREFIX_ERROR_CLASSES = "border-red-500".freeze
  PHONE_PREFIX_NORMAL_CLASSES = "border-gray-300".freeze

  ASTERISK_BASE_CLASSES = "text-3xl leading-none font-normal absolute left-4 top-4 pointer-events-none z-10".freeze
  ASTERISK_ERROR_CLASSES = "text-red-500".freeze
  ASTERISK_NORMAL_CLASSES = "text-gray-400".freeze

  attr_reader :form, :field_name, :field_type, :required, :placeholder, :validation_rules, :options, :errors

  def initialize(form:, field:, type: :text, required: false, placeholder: nil, validation_rules: nil, options: {})
    @form = form
    @field_name = field
    @field_type = type
    @required = required
    @placeholder = placeholder
    @validation_rules = validation_rules
    @options = options
    @errors = get_field_errors(form, field)
  end

  def show_counter?
    options[:show_counter] == true && field_type == :textarea
  end

  def max_length
    options[:maxlength] || 100
  end

  def current_length
    get_field_value(form, field_name).to_s.length
  end

  def field_id
    "#{get_object_name(form)}_#{field_name}"
  end

  def has_errors?
    errors && errors.any?
  end

  def container_classes
    return "w-full" if field_type == :submit

    class_names(
      "form-field relative w-full",
      "form-field--required": required,
      "form-field--error": has_errors?
    )
  end

  def input_classes_for(type = field_type)
    class_names(
      base_input_classes,
      field_specific_classes(type),
      error_classes,
      options[:class]
    )
  end

  def input_field_classes
    input_classes_for(field_type)
  end

  def field_attributes
    base_attrs = build_base_attributes
    filtered_opts = filtered_options

    if filtered_opts[:data] && base_attrs[:data]
      base_attrs[:data] = base_attrs[:data].merge(filtered_opts[:data])
      filtered_opts = filtered_opts.except(:data)
    end

    base_attrs.merge!(filtered_opts)
  end

  def label_attributes
    {
      for: field_id,
      class: "sr-only"
    }
  end

  def label_text
    field_name.to_s.humanize
  end

  def aria_describedby
    ids = []
    ids << "#{field_id}_error" if has_errors?
    ids << "#{field_id}_help" if options[:helper_text]
    ids << "#{field_id}_counter" if show_counter?
    ids.join(" ").presence
  end

  def data_attributes
    {}.tap do |attrs|
      add_character_counter_data(attrs) if show_counter?
      add_validation_data(attrs) if validation_rules
      add_option_data_attributes(attrs)
    end
  end

  def required_indicator
    return unless required && field_type != :radio_group && field_type != :submit

    content_tag :span, "*",
      class: class_names(
        ASTERISK_BASE_CLASSES,
        has_errors? ? ASTERISK_ERROR_CLASSES : ASTERISK_NORMAL_CLASSES
      ),
      "aria-hidden" => "true"
  end

  def phone_prefix
    options[:phone_prefix] || "+961"
  end

  def container_data_attributes
    attrs = {}

    controllers = []
    controllers << "character-counter" if show_counter?

    attrs[:controller] = controllers.join(" ") unless controllers.empty?

    if show_counter?
      attrs[:'character-counter-max-value'] = max_length
    end

    attrs
  end

  def validation_controller_data
    validation_rules ? { controller: "form-validation" } : {}
  end

  def textarea_rows
    options[:rows] || 1
  end

  def render_field_input
    case normalized_field_type
    when :textarea then render_textarea_field
    when :email then render_email_field
    when :tel then render_phone_field
    when :password then render_password_field
    when :radio_group then render_radio_group
    when :submit then render_submit_button
    else render_text_field
    end
  end

  private

  def render_text_field
    form.text_field field_name, field_attributes
  end

  def render_email_field
    form.email_field field_name, field_attributes
  end

  def render_password_field
    form.password_field field_name, field_attributes
  end


  def render_textarea_field
    form.text_area field_name, field_attributes.merge(rows: textarea_rows)
  end

  def render_phone_field
    content_tag :div, class: PHONE_CONTAINER_CLASSES do
      prefix_span = content_tag :span, phone_prefix,
        class: class_names(
          PHONE_PREFIX_BASE_CLASSES,
          has_errors? ? PHONE_PREFIX_ERROR_CLASSES : PHONE_PREFIX_NORMAL_CLASSES
        )

      phone_field = form.telephone_field field_name, field_attributes

      prefix_span + phone_field
    end
  end

  def render_radio_group
    content_tag :div, class: "form-radio-group" do
      radio_options.map do |label, value|
        render_radio_option(label, value)
      end.join.html_safe
    end
  end

  def render_radio_option(label, value)
    content_tag :label, class: "form-radio-option" do
      radio_button = form.radio_button field_name, value,
        class: "form-radio-input",
        data: radio_button_data_attributes

      label_span = content_tag :span, label, class: "form-radio-label"

      description_div = if field_name == :payment_method && options[:descriptions]&.[](value)
        content_tag :div, options[:descriptions][value], class: "text-sm text-gray-500 mt-1"
      else
        ""
      end

      radio_button + content_tag(:div, label_span + description_div, class: "ml-3")
    end
  end

  def radio_options
    options[:options] || []
  end

  def radio_button_data_attributes
    attrs = options[:data] || {}
    attrs[:action] = options[:radio_action] if options[:radio_action]
    attrs
  end

  def render_submit_button
    button_text = options[:text] || field_name.to_s.humanize
    button_attrs = {
      type: "submit",
      class: submit_button_classes,
      data: submit_button_data_attributes
    }

    content_tag :button, button_text, button_attrs
  end

  def submit_button_classes
    options[:css_class] || default_submit_button_classes
  end

  def default_submit_button_classes
    SUBMIT_BUTTON_CLASSES
  end

  def submit_button_data_attributes
    attrs = options[:data] || {}
    attrs[:action] = options[:data_action] if options[:data_action]
    attrs
  end

  def base_input_classes
    BASE_INPUT_CLASSES
  end

  def field_specific_classes(type = field_type)
    normalized_type = normalize_field_type(type)
    FIELD_SPECIFIC_CLASSES[normalized_type] || FIELD_SPECIFIC_CLASSES[:text]
  end

  def error_classes
    has_errors? ? ERROR_CLASSES : ""
  end

  def get_field_errors(form, field)
    if form.respond_to?(:object) && form.object.respond_to?(:errors)
      form.object.errors[field]
    elsif form.respond_to?(:model) && form.model.respond_to?(:errors)
      form.model.errors[field]
    else
      []
    end
  end

  def get_field_value(form, field)
    if form.respond_to?(:object) && form.object.respond_to?(field)
      form.object.send(field)
    elsif form.respond_to?(:model) && form.model.respond_to?(field)
      form.model.send(field)
    else
      ""
    end
  end

  def get_object_name(form)
    if form.respond_to?(:object_name)
      form.object_name
    elsif form.respond_to?(:model)
      form.model.class.name.underscore
    else
      "form"
    end
  end

  def build_base_attributes
    {
      id: field_id,
      class: input_field_classes,
      placeholder: placeholder,
      "aria-describedby" => aria_describedby,
      "aria-invalid" => has_errors?.to_s,
      data: data_attributes
    }
  end

  def filtered_options
    options.except(:class, :helper_text, :show_counter, :rows, :maxlength, :options, :phone_prefix)
  end

  def add_character_counter_data(attrs)
    attrs[:'character-counter-target'] = "input"
    attrs[:action] = "input->character-counter#input paste->character-counter#paste cut->character-counter#cut"
  end

  def add_validation_data(attrs)
    attrs[:'validation-rules'] = validation_rules
    # Translation injection moved to controller level to avoid conflicts
  end

  def add_option_data_attributes(attrs)
    option_data_attrs = options.select { |key, _| key.to_s.start_with?("data-") }
    attrs.merge!(option_data_attrs)
  end

  def normalized_field_type
    normalize_field_type(field_type)
  end

  def normalize_field_type(type)
    type == :phone ? :tel : type
  end
end
