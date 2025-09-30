# frozen_string_literal: true

class DeliveryScheduleService
  def initialize(method:, city: "Beirut", selected_date: nil, selected_time: nil)
    @delivery_method = method
    @city = city
    @selected_date = selected_date
    @selected_time = selected_time
  end

  def title_for_method
    I18n.t("delivery_schedule.titles.#{delivery_method}", default: I18n.t("delivery_schedule.titles.pickup"))
  end

  def subtitle_for_method
    I18n.t("delivery_schedule.subtitles.#{delivery_method}", default: I18n.t("delivery_schedule.subtitles.pickup"))
  end

  def available_options
    case delivery_method
    when "courier"
      generate_courier_options
    else
      generate_pickup_options
    end
  end

  def available_dates
    available_options.map { |option| option[:date] }.uniq
  end

  def option_selected?(date, time)
    return false unless selected_date && selected_time

    selected_date.strftime("%Y-%m-%d") == date.strftime("%Y-%m-%d") &&
      selected_time == time
  end

  def option_disabled?(date, time)
    if delivery_method == "courier" && date.today? && !DeliveryConfiguration.same_day_enabled_for?(delivery_method)
      return true
    end

    if date.today?
      return time_slot_has_passed?(time, date)
    end

    false
  end

  def placeholder_text
    case delivery_method
    when "courier"
      I18n.t("delivery_schedule.placeholders.courier")
    else
      pickup_start = I18n.l(Date.current, format: :short)
      pickup_end = I18n.l(Date.current + 2.days, format: :short)
      I18n.t("delivery_schedule.placeholders.pickup", start_date: pickup_start, end_date: pickup_end)
    end
  end

  def has_selection?
    selected_date.present? && selected_time.present?
  end

  def current_selection_display
    return "" unless has_selection?

    date_display = I18n.l(selected_date, format: I18n.t("delivery_schedule.date_formats.display"))
    "#{date_display} - #{selected_time}"
  end

  def option_value(date, time)
    "#{date.strftime('%Y-%m-%d')}|#{time}"
  end

  private

  attr_reader :delivery_method, :city, :selected_date, :selected_time

  def generate_courier_options
    generate_options_for_method("courier")
  end

  def generate_pickup_options
    generate_options_for_method("pickup")
  end

  def format_date_display(date)
    if date.today?
      I18n.t("delivery_schedule.relative_dates.today")
    elsif date == Date.tomorrow
      I18n.t("delivery_schedule.relative_dates.tomorrow")
    else
      I18n.l(date, format: I18n.t("delivery_schedule.date_formats.short"))
    end
  end

  def generate_options_for_method(method)
    options = []
    config = DeliveryConfiguration.config_for_city_and_method(city, method)
    base_date = DeliveryConfiguration.base_date_for(method)
    time_slots = config[:time_slots] || [ config[:store_hours] || DeliveryConfiguration.store_hours ]

    config[:days_ahead].each do |day_offset|
      date = base_date + day_offset.days

      time_slots.each do |time_slot|
        options << {
          date: date,
          time: time_slot,
          display: "#{format_date_display(date)} - #{time_slot}",
          value: option_value(date, time_slot),
          disabled: option_disabled?(date, time_slot),
          selected: option_selected?(date, time_slot)
        }
      end
    end

    options
  end

  def time_slot_has_passed?(time_slot, date)
    begin
      time_range = TimeSlotParser.parse_datetime_range(time_slot, date)
      return true unless time_range[:start_datetime]

      time_range[:start_datetime] <= Time.current
    rescue StandardError
      true
    end
  end
end
