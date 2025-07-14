class CreateCategorizations < ActiveRecord::Migration[8.0]
  def change
    create_table :categorizations do |t|
      t.references :product, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :categorizations, [ :product_id, :category_id ], unique: true
  end
end
