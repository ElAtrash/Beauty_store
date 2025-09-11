class AddLebanonFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :phone_number, :string, null: false
    add_column :orders, :delivery_method, :string, default: 'courier'
    add_column :orders, :courier_name, :string
    add_column :orders, :delivery_notes, :text

    # Update fulfillment_status to have default value
    change_column_default :orders, :fulfillment_status, 'unfulfilled'

    # Add index for phone number for quick lookups
    add_index :orders, :phone_number
    add_index :orders, :delivery_method
  end
end
