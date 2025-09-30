# frozen_string_literal: true

module StoreInformation
  extend ActiveSupport::Concern

  private

  # Delegate common store information methods to the service
  def store_name
    StoreConfigurationService.name
  end

  def store_address(city: nil)
    StoreConfigurationService.full_address(city: city)
  end

  def store_phone
    StoreConfigurationService.phone
  end

  def store_email
    StoreConfigurationService.email
  end

  def store_working_hours
    StoreConfigurationService.working_hours
  end

  # Formatted store information for common use cases
  def store_info(city: nil)
    StoreConfigurationService.basic_info(city: city)
  end

  def store_contact_info
    StoreConfigurationService.contact_info
  end

  def store_pickup_details
    StoreConfigurationService.pickup_details
  end

  def store_full_info
    StoreConfigurationService.full_info
  end
end
