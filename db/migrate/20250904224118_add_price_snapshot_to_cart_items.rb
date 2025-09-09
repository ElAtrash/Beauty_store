class AddPriceSnapshotToCartItems < ActiveRecord::Migration[8.0]
  def change
    add_column :cart_items, :price_snapshot_cents, :integer, null: false, default: 0
    add_column :cart_items, :price_snapshot_currency, :string, null: false, default: "USD", limit: 3

    add_index :cart_items, :price_snapshot_cents
  end
end
