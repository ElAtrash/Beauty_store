class MigrateDefaultDeliveryAddressToAddresses < ActiveRecord::Migration[8.0]
  def up
    # Migrate existing default_delivery_address JSONB data to Address records
    CustomerProfile.find_each do |profile|
      next unless profile.has_default_address?
      next if profile.user.addresses.exists? # Skip if already migrated

      addr = profile.default_delivery_address

      begin
        profile.user.addresses.create!(
          label: addr["label"].presence || CustomerProfile::DEFAULT_ADDRESS_LABEL,
          address_line_1: addr["address_line_1"],
          address_line_2: addr["address_line_2"],
          city: addr["city"],
          governorate: addr["governorate"].presence || StoreConfigurationService::DEFAULT_GOVERNORATE,
          landmarks: addr["landmarks"],
          phone_number: addr["phone_number"],
          default: true
        )

        Rails.logger.info "Migrated address for user #{profile.user_id}"
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Failed to migrate address for user #{profile.user_id}: #{e.message}"
      end
    end
  end

  def down
    # Reverse migration: copy Address records back to JSONB
    User.includes(:addresses, :customer_profile).find_each do |user|
      next unless user.default_address
      next unless user.customer_profile

      addr = user.default_address

      user.customer_profile.update!(
        default_delivery_address: {
          label: addr.label,
          address_line_1: addr.address_line_1,
          address_line_2: addr.address_line_2,
          city: addr.city,
          governorate: addr.governorate,
          landmarks: addr.landmarks,
          phone_number: addr.phone_number,
          last_used_at: addr.updated_at
        }
      )
    end

    # Don't delete Address records in down migration (safety measure)
  end
end
