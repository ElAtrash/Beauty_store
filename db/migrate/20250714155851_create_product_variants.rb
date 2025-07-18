class CreateProductVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.string :sku, null: false
      t.string :barcode

      t.monetize :price, null: false
      t.monetize :compare_at_price
      t.monetize :cost

      t.string :color
      t.string :size
      t.string :volume

      t.integer :stock_quantity, default: 0, null: false
      t.boolean :track_inventory, default: true, null: false
      t.boolean :allow_backorder, default: false, null: false

      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :product_variants, :sku, unique: true
    add_index :product_variants, [ :product_id, :position ]
  end
end
