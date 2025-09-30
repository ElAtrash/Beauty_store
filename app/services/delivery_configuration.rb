# frozen_string_literal: true

module DeliveryConfiguration
  COURIER_CONFIG = {
    time_slots: [
      "09:00-12:00",
      "12:00-15:00",
      "15:00-18:00",
      "18:00-21:00"
    ].freeze,
    days_ahead: 0..4,
    same_day_enabled: false,
    base_date_offset: 1
  }.freeze

  PICKUP_CONFIG = {
    store_hours: "09:00-21:00",
    days_ahead: 0..2,
    same_day_enabled: true,
    base_date_offset: 0
  }.freeze

  CITY_CONFIGS = {
    "Beirut" => {
      courier: COURIER_CONFIG,
      pickup: PICKUP_CONFIG
    }
  }.freeze

  class << self
    def time_slots_for(method)
      config_for(method)[:time_slots]
    end

    def days_ahead_for(method)
      config_for(method)[:days_ahead]
    end

    def same_day_enabled_for?(method)
      config_for(method)[:same_day_enabled]
    end

    def base_date_for(method)
      offset = config_for(method)[:base_date_offset]
      offset.days.from_now.to_date
    end

    def store_hours
      PICKUP_CONFIG[:store_hours]
    end

    def config_for_city_and_method(city, method)
      city_config = CITY_CONFIGS[city] || CITY_CONFIGS["Beirut"]
      city_config[method.to_sym]
    end

    private

    def config_for(method)
      case method.to_s
      when "courier"
        COURIER_CONFIG
      when "pickup"
        PICKUP_CONFIG
      else
        PICKUP_CONFIG
      end
    end
  end
end
