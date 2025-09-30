# frozen_string_literal: true

class StoreConfigurationService
  class << self
    def config
      @config ||= load_configuration
    end

    def store_config
      config["store"]
    end

    def name
      store_config["name"]
    end

    def full_address(city: nil)
      location = store_config["location"]
      city_name = city || location["city"]
      "#{location['address']}, #{city_name}, #{location['country']}"
    end

    def address
      store_config["location"]["address"]
    end

    def city
      store_config["location"]["city"]
    end

    def country
      store_config["location"]["country"]
    end

    def coordinates
      store_config["location"]["coordinates"]
    end

    def phone
      store_config["contact"]["phone"]
    end

    def email
      store_config["contact"]["email"]
    end

    def support_phone
      store_config["contact"]["support_phone"]
    end

    def support_email
      store_config["contact"]["support_email"]
    end

    def working_hours
      store_config["business"]["working_hours"]
    end

    def pickup_policy
      store_config["business"]["pickup_policy"]
    end

    def pickup_cost
      store_config["business"]["pickup_cost"]
    end

    def pickup_availability
      store_config["business"]["pickup_availability"]
    end

    def directions
      store_config["business"]["directions"]
    end

    # Social media
    def website
      store_config["social"]["website"]
    end

    def instagram
      store_config["social"]["instagram"]
    end

    def facebook
      store_config["social"]["facebook"]
    end

    # Formatted data for components
    def basic_info(city: nil)
      {
        name: name,
        address: full_address(city: city)
      }
    end

    def contact_info
      {
        phone: phone,
        email: email,
        support_phone: support_phone,
        support_email: support_email,
        working_hours: working_hours
      }
    end

    def pickup_details
      {
        name: name,
        address: full_address,
        cost: pickup_cost,
        delivery_date: pickup_availability,
        working_hours: working_hours,
        shelf_life: pickup_policy,
        phone: phone,
        coordinates: coordinates,
        directions: directions
      }
    end

    def full_info
      {
        name: name,
        contact: contact_info,
        location: {
          address: address,
          city: city,
          country: country,
          coordinates: coordinates,
          full_address: full_address
        },
        business: {
          working_hours: working_hours,
          pickup_policy: pickup_policy,
          pickup_cost: pickup_cost,
          pickup_availability: pickup_availability,
          directions: directions
        },
        social: {
          website: website,
          instagram: instagram,
          facebook: facebook
        }
      }
    end

    # Delivery and Payment Methods
    def delivery_methods_config
      config["delivery_methods"] || {}
    end

    def payment_methods_config
      config["payment_methods"] || {}
    end

    def delivery_method_options
      delivery_methods_config.filter_map do |key, method_config|
        next unless method_config["enabled"]
        [ method_config["label"], key ]
      end
    end

    def payment_method_options
      payment_methods_config.filter_map do |key, method_config|
        next unless method_config["enabled"]
        [ method_config["label"], key ]
      end
    end

    def payment_method_description(key)
      payment_methods_config.dig(key, "description")
    end

    def payment_method_descriptions
      payment_methods_config.transform_values { |config| config["description"] }.compact
    end

    # For SEO and meta tags
    def seo_title_suffix
      " | #{name}"
    end

    def default_meta_description
      "Premium beauty products at #{name}."
    end

    private

    def load_configuration
      config_file = Rails.root.join("config", "store.yml")
      raise "Store configuration file not found: #{config_file}" unless File.exist?(config_file)

      yaml_content = YAML.load_file(config_file, aliases: true)
      environment_config = yaml_content[Rails.env] || yaml_content["default"]

      raise "Store configuration not found for environment: #{Rails.env}" unless environment_config

      environment_config
    end

    # Reload configuration (useful for development/testing)
    def reload!
      @config = nil
      load_configuration
    end
  end
end
