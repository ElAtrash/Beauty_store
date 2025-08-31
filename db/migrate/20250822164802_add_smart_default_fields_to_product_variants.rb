class AddSmartDefaultFieldsToProductVariants < ActiveRecord::Migration[8.0]
  def change
    add_column :product_variants, :conversion_score, :decimal, precision: 8, scale: 4, default: 0.0, null: false
    add_column :product_variants, :sales_count, :integer, default: 0, null: false
    add_column :product_variants, :is_default, :boolean, default: false, null: false
    add_column :product_variants, :canonical_variant, :boolean, default: false, null: false

    # Add indexes for performance
    add_index :product_variants, [ :product_id, :is_default ], name: 'index_product_variants_on_product_and_default'
    add_index :product_variants, [ :product_id, :conversion_score ], name: 'index_product_variants_on_product_and_conversion'
    add_index :product_variants, [ :product_id, :sales_count ], name: 'index_product_variants_on_product_and_sales'
  end
end
