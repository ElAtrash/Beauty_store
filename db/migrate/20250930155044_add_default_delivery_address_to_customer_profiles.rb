class AddDefaultDeliveryAddressToCustomerProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :customer_profiles, :default_delivery_address, :jsonb, default: {}
  end
end
