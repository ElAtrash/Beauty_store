# frozen_string_literal: true

class TimeSlotParser
  def self.parse_time_slot(time_slot_string, date = nil)
    new(time_slot_string, date).parse
  end

  def self.parse_delivery_time(time_slot_string, date)
    new(time_slot_string, date).parse_start_datetime
  end

  def self.parse_datetime_range(time_slot_string, date)
    new(time_slot_string, date).parse_datetime_range
  end

  def self.valid?(time_slot_string)
    new(time_slot_string).valid?
  end

  def initialize(time_slot_string, date = nil)
    @time_slot_string = time_slot_string
    @date = date || Time.zone.today
  end

  def parse
    return { start_time: nil, end_time: nil } unless valid_format?

    start_time_str, end_time_str = @time_slot_string.split(/\s*-\s*/, 2)
    start_time = parse_time_string(start_time_str)
    end_time = parse_time_string(end_time_str)

    return { start_time: nil, end_time: nil } unless start_time && end_time

    {
      start_time: start_time,
      end_time: end_time
    }
  end

  def parse_start_datetime
    result = parse
    return nil unless result[:start_time]

    @date.beginning_of_day + result[:start_time].seconds_since_midnight.seconds
  end

  def parse_datetime_range
    result = parse
    return { start_datetime: nil, end_datetime: nil } unless result[:start_time] && result[:end_time]

    base_datetime = @date.beginning_of_day

    {
      start_datetime: base_datetime + result[:start_time].seconds_since_midnight.seconds,
      end_datetime: base_datetime + result[:end_time].seconds_since_midnight.seconds
    }
  end

  def valid?
    return false unless valid_format?

    start_time_str, end_time_str = @time_slot_string.split(/\s*-\s*/, 2)
    valid_time_string?(start_time_str) && valid_time_string?(end_time_str)
  end

  private

  def valid_format?
    @time_slot_string.present? && @time_slot_string.match?(/\s*-\s*/)
  end

  def valid_time_string?(time_str)
    return false unless time_str

    time_parts = time_str.strip.match(/(\d{1,2})(?::(\d{2}))?\s*(AM|PM)/i)
    return false unless time_parts

    hour = time_parts[1].to_i
    minute = time_parts[2]&.to_i || 0

    # Validate hour and minute ranges
    hour >= 1 && hour <= 12 && minute >= 0 && minute <= 59
  end

  def parse_time_string(time_str)
    return nil unless valid_time_string?(time_str)

    time_parts = time_str.strip.match(/(\d{1,2})(?::(\d{2}))?\s*(AM|PM)/i)
    hour = time_parts[1].to_i
    minute = time_parts[2]&.to_i || 0
    period = time_parts[3].upcase

    # Convert to 24-hour format
    hour = 0 if period == "AM" && hour == 12
    hour += 12 if period == "PM" && hour != 12

    begin
      # Use the stored @date to avoid midnight edge cases when object is reused
      Time.zone.local(@date.year, @date.month, @date.day, hour, minute)
    rescue ArgumentError
      nil
    end
  end
end
