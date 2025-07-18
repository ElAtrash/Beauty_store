class CreateCollectionProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_products do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :collection_products, [ :collection_id, :product_id ], unique: true
    add_index :collection_products, [ :collection_id, :position ]
  end
end
