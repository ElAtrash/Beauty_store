# frozen_string_literal: true

class OrderConfirmation::TimelineComponent < ViewComponent::Base
  FULFILLMENT_ORDER = [ :unfulfilled, :processing, :packed, :dispatched, :delivered, :picked_up, :cancelled ].freeze

  STEP_CONFIGS = {
    dispatched: { has_estimate: true }
  }.freeze

  STYLE_THEMES = {
    completed: {
      icon_wrapper: "border-green-500 text-green-600 bg-green-50",
      text: "text-text-primary",
      connector: "bg-green-300"
    },
    current: {
      icon_wrapper: "border-interactive-primary text-interactive-primary bg-orange-50",
      text: "text-text-primary",
      connector: "bg-gray-300"
    },
    pending: {
      icon_wrapper: "border-gray-300 text-gray-400",
      text: "text-text-muted",
      connector: "bg-gray-300"
    },
    cancelled_completed: {
      icon_wrapper: "border-gray-400 text-gray-500 bg-gray-50",
      text: "text-gray-600",
      connector: "bg-gray-300"
    }
  }.freeze

  def initialize(order:, **options)
    @order = order
    @options = options
  end

  attr_reader :order, :options

  def timeline_steps
    @timeline_steps ||= order.cancelled? ? cancelled_steps : normal_steps
  end

  def progress_percentage
    return 100 if order.cancelled?

    return 0 if order.fulfillment_status.nil?
    current_index = FULFILLMENT_ORDER.index(order.fulfillment_status.to_sym)
    return 0 if current_index.nil?

    max_index = timeline_steps.map { |step| FULFILLMENT_ORDER.index(step[:key].to_sym) }.max
    return 0 if max_index.nil? || max_index.zero?

    ((current_index.to_f / max_index) * 100).round
  end

  def container_classes
    class_names("border border-gray-200 p-6 shadow-sm", options[:class])
  end

  def progress_bar_color
    order.cancelled? ? "bg-gray-400" : "bg-green-500"
  end

  private

  def cancelled_steps
    [ build_step(:unfulfilled), build_step(:cancelled) ]
  end

  def normal_steps
    base_steps = [ :unfulfilled, :processing ]
    final_steps = order.courier? ? [ :packed, :dispatched, :delivered ] : [ :packed, :picked_up ]
    (base_steps + final_steps).map { |status| build_step(status) }
  end


  def build_step(status)
    completed = status_completed?(status)
    current = status_current?(status)
    theme_key = determine_theme(completed, current)

    {
      key: status,
      title: I18n.t("order.timeline.#{status}_title"),
      description: I18n.t("order.timeline.#{status}_description"),
      completed: completed,
      current: current,
      estimated_time: calculate_estimated_time(status),
      theme: STYLE_THEMES[theme_key]
    }
  end

  def calculate_estimated_time(status)
    return nil if order.cancelled? || status != :dispatched
    delivery_estimate_for_shipping
  end

  def delivery_estimate_for_shipping
    return unless order.courier?
    TimeSlotParser.parse_delivery_time(order.delivery_time_slot, order.delivery_date)
  end

  def determine_theme(completed, current)
    return :cancelled_completed if order.cancelled? && completed
    return :pending if order.cancelled?
    return :completed if completed
    return :current if current
    :pending
  end

  def status_position(status)
    {
      current: order.fulfillment_status.nil? ? nil : FULFILLMENT_ORDER.index(order.fulfillment_status.to_sym),
      target: FULFILLMENT_ORDER.index(status.to_sym)
    }
  end

  def status_completed?(status)
    return false if order.cancelled? && status != :cancelled
    return true if status == :cancelled && order.cancelled?

    pos = status_position(status)
    return false if pos[:current].nil? || pos[:target].nil?

    is_final_state = order.delivered? || order.picked_up?
    pos[:current] > pos[:target] || (is_final_state && pos[:current] >= pos[:target])
  end

  def status_current?(status)
    order.fulfillment_status == status.to_s
  end

  def step_item_classes(step)
    class_names(
      "flex items-start space-x-4 relative",
      "pb-8" => !last_step?(step),
      "pb-0" => last_step?(step)
    )
  end

  def step_icon_wrapper_classes(step)
    class_names(
      "relative z-10 flex items-center justify-center w-10 h-10 border-2 bg-white rounded-full flex-shrink-0",
      step[:theme][:icon_wrapper]
    )
  end

  def step_connector_classes(step)
    return "hidden" if last_step?(step)

    class_names(
      "absolute left-5 top-10 w-0.5 h-full -ml-px",
      step[:theme][:connector]
    )
  end

  def step_title_classes(step)
    class_names("text-sm font-medium", step[:theme][:text])
  end

  def step_description_classes(step)
    class_names("text-xs mt-1", step[:theme][:text])
  end

  def step_icon_name(step)
    return :check_circle if step[:completed]
    return :clock if step[:current]
    :info
  end

  def last_step?(step)
    timeline_steps.last == step
  end
end
