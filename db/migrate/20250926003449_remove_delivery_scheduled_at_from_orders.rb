class RemoveDeliveryScheduledAtFromOrders < ActiveRecord::Migration[8.0]
  def change
    remove_column :orders, :delivery_scheduled_at, :datetime
  end
end
