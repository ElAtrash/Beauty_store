class AddProductAttributesToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :product_attributes, :jsonb, default: {}
    add_index :products, :product_attributes, using: :gin

    # Add check constraint for data validation
    add_check_constraint :products,
                        "jsonb_typeof(product_attributes) = 'object'",
                        name: 'product_attributes_is_object'
  end
end
