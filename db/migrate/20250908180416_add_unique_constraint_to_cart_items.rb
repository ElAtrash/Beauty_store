class AddUniqueConstraintToCartItems < ActiveRecord::Migration[8.0]
  def change
    # Remove existing non-unique index first
    remove_index :cart_items, [ :cart_id, :product_variant_id ], if_exists: true

    # Add unique constraint to prevent duplicate cart items
    add_index :cart_items, [ :cart_id, :product_variant_id ], unique: true, name: 'index_cart_items_on_cart_id_and_product_variant_id'
  end
end
