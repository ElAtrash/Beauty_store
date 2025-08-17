class EnhanceSizeSelectionSchema < ActiveRecord::Migration[8.0]
  def change
    # Remove old size columns
    remove_column :product_variants, :size, :string
    remove_column :product_variants, :volume, :string

    # Add new structured size columns
    add_column :product_variants, :size_value, :decimal, precision: 10, scale: 2
    add_column :product_variants, :size_unit, :string
    add_column :product_variants, :size_type, :string

    # Add index for better query performance
    add_index :product_variants, [ :size_type, :size_value ]
  end
end
