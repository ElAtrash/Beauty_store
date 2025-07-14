class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :product_type
      t.references :brand, foreign_key: true

      t.text :ingredients
      t.text :how_to_use
      t.string :skin_types, array: true, default: []

      t.boolean :active, default: true, null: false
      t.datetime :published_at

      t.string :meta_title
      t.text :meta_description
      t.integer :reviews_count, default: 0, null: false

      t.timestamps
    end

    add_index :products, :slug, unique: true
    add_index :products, [ :active, :published_at ]
  end
end
