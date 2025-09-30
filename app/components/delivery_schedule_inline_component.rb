# frozen_string_literal: true

class DeliveryScheduleInlineComponent < ViewComponent::Base
  attr_reader :delivery_method, :selected_date, :selected_time

  def initialize(delivery_method:, selected_date: nil, selected_time: nil)
    @delivery_method = delivery_method
    @selected_date = selected_date
    @selected_time = selected_time
    @delivery_service = DeliveryScheduleService.new(
      method: delivery_method,
      selected_date: selected_date,
      selected_time: selected_time
    )
  end

  private

  attr_reader :delivery_service

  def time_slots_for_date(date)
    delivery_service.available_options.select { |option| option[:date] == date }
  end

  def formatted_time_slots_for_date(date)
    time_slots_for_date(date).map do |slot|
      {
        time: slot[:time],
        display: time_slot_display(slot[:time]),
        disabled: option_disabled?(date, slot[:time])
      }
    end
  end

  def time_slots_data
    delivery_service.available_dates.each_with_object({}) do |date, hash|
      hash[date.strftime("%Y-%m-%d")] = formatted_time_slots_for_date(date)
    end
  end

  def date_display(date)
    if date.today?
      I18n.t("delivery_schedule.relative_dates.today")
    elsif date == Date.tomorrow
      I18n.t("delivery_schedule.relative_dates.tomorrow")
    else
      I18n.l(date, format: I18n.t("delivery_schedule.date_formats.picker")).downcase
    end
  end

  def date_number(date)
    date.day
  end

  def date_day_abbr(date)
    date.strftime("%a").downcase
  end

  def time_slot_display(time_slot)
    result = TimeSlotParser.parse_time_slot(time_slot)
    return time_slot unless result[:start_time] && result[:end_time]

    start_24h = sprintf("%02d:%02d", result[:start_time].hour, result[:start_time].min)
    end_24h = sprintf("%02d:%02d", result[:end_time].hour, result[:end_time].min)
    "#{start_24h}-#{end_24h}"
  end

  def option_selected?(date, time_slot)
    return false unless selected_date && selected_time

    selected_date.to_date == date.to_date && selected_time == time_slot
  end

  def option_disabled?(date, time_slot)
    delivery_service.option_disabled?(date, time_slot)
  end

  def show_inline_picker?
    delivery_method == "courier"
  end

  def date_button_classes(date)
    class_names(
      "date-button flex-shrink-0",
      "selected" => option_selected?(date, time_slots_for_date(date).first&.dig(:time))
    )
  end
end
