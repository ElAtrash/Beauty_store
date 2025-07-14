class CreateBrands < ActiveRecord::Migration[8.0]
  def change
    create_table :brands do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :logo_url
      t.boolean :featured, default: false, null: false

      t.timestamps
    end

    add_index :brands, :slug, unique: true
  end
end
