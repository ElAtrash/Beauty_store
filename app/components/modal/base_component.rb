# frozen_string_literal: true

class Modal::BaseComponent < ViewComponent::Base
  attr_reader :id, :title, :size, :position

  SIZE_OPTIONS = %i[medium full].freeze
  POSITION_OPTIONS = %i[left right center].freeze
  POSITION_CONFIG = {
    left: {
      container: "left-0",
      panel_base: "left-0",
      panel_closed: "translate-x-[-100%]",
      panel_open: "translate-x-0"
    },
    right: {
      container: "right-0",
      panel_base: "right-0",
      panel_closed: "translate-x-full",
      panel_open: "translate-x-0"
    },
    center: {
      container: "inset-x-0 flex items-center justify-center",
      panel_base: [ "left-1/2", "top-1/2", "h-auto", "max-h-[90vh]", "rounded-lg" ],
      panel_closed: "translate-x-[-50%] translate-y-[-50%] scale-95",
      panel_open: "translate-x-[-50%] translate-y-[-50%] scale-100"
    }
  }.freeze

  def initialize(id:, title:, size: :medium, position: :right, **options)
    @id = id
    @title = title
    @size = validate_size(size)
    @position = validate_position(position)
    @options = options
  end

  renders_one :body
  renders_one :header_action
  renders_one :footer

  private

  attr_reader :options

  def validate_size(size)
    size = size.to_sym
    return size if SIZE_OPTIONS.include?(size)
    raise ArgumentError, "Invalid size: #{size}. Must be one of: #{SIZE_OPTIONS.join(', ')}"
  end

  def validate_position(position)
    position = position.to_sym
    return position if POSITION_OPTIONS.include?(position)
    raise ArgumentError, "Invalid position: #{position}. Must be one of: #{POSITION_OPTIONS.join(', ')}"
  end

  def container_data_attributes
    additional_attrs = additional_data_attributes.dup
    controllers_list = [ "modal" ]
    controllers_list << additional_attrs.delete(:controller) if additional_attrs[:controller]

    base_data = {
      controller: controllers_list.join(" "),
      modal_id_value: id,
      modal_backdrop_close_value: backdrop_closes?,
      action: "keydown@window->modal#handleKeydown"
    }

    {
      data: base_data.merge(additional_attrs)
    }
  end

  def additional_data_attributes
    options.fetch(:data, {})
  end

  def backdrop_closes?
    options.fetch(:backdrop_closes, true)
  end

  def container_classes
    class_names(
      "fixed", "inset-y-0", "z-[120]",
      "modal-closed",
      position_container_classes,
      size_container_classes,
      options[:class]
    )
  end

  def position_container_classes
    POSITION_CONFIG[position][:container]
  end

  def size_container_classes
    return "w-full" if position == :center

    if size == :full
      "w-full"
    else
      "w-[680px] max-w-[90vw]"
    end
  end

  def overlay_classes
    class_names(
      "fixed", "inset-0",
      "bg-gray-900/50", "backdrop-blur-sm",
      "transition-all", "duration-300", "ease-in-out",
      "z-[120]"
    )
  end

  def panel_classes
    class_names(
      "fixed", "top-0", "h-screen",
      "bg-white", "shadow-xl",
      "transform", "transition-transform", "duration-300", "ease-in-out",
      "flex", "flex-col",
      "z-[121]",
      panel_base_position_classes,
      panel_size_classes
    )
  end

  def panel_base_position_classes
    POSITION_CONFIG[position][:panel_base]
  end

  def panel_size_classes
    return center_panel_size_classes if position == :center

    base_classes = [ "box-border" ]

    responsive_classes = if size == :full
      [ "w-full", "max-w-none" ]
    else
      [ "w-[680px]", "min-w-[680px]", "max-w-[90vw]" ]
    end

    mobile_classes = [ "max-md:w-full", "max-md:max-w-full", "max-md:min-w-0" ]

    base_classes + responsive_classes + mobile_classes
  end

  def center_panel_size_classes
    if size == :full
      [ "w-full", "max-w-4xl" ]
    else
      [ "w-full", "max-w-2xl" ]
    end
  end

  def header_classes
    class_names(
      "flex", "items-center", "justify-between",
      "px-8", "pt-8", "pb-4", "sm:px-12", "sm:pt-8", "sm:pb-4",
      "bg-white", "shrink-0"
    )
  end

  def title_classes
    class_names(
      "text-lg", "font-semibold", "text-gray-900",
      "truncate", "pr-4"
    )
  end

  def content_classes
    class_names(
      "flex-1", "overflow-y-auto", "overflow-x-hidden",
      "px-8", "sm:px-12", "pt-4", "pb-4"
    )
  end

  def footer_classes
    class_names(
      "shrink-0",
      "px-8", "sm:px-12", "pb-8"
    )
  end

  def close_button_classes
    class_names(
      "flex", "items-center", "justify-center",
      "w-8", "h-8", "p-0"
    )
  end

  def aria_attributes
    {
      role: "dialog",
      "aria-modal": "true",
      "aria-labelledby": "#{id}-title",
      "aria-describedby": "#{id}-content"
    }
  end

  def has_header_action?
    header_action.present? || (respond_to?(:header_actions, true) && header_actions.present?)
  end

  def has_footer?
    footer.present? || (respond_to?(:footer_content, true) && footer_content.present?)
  end

  def open_state_classes
    {
      container: "block",
      overlay: "opacity-100 visible pointer-events-auto",
      panel: POSITION_CONFIG[position][:panel_open]
    }
  end

  def closed_state_classes
    {
      container: "hidden",
      overlay: "opacity-0 invisible pointer-events-none",
      panel: POSITION_CONFIG[position][:panel_closed]
    }
  end
end
