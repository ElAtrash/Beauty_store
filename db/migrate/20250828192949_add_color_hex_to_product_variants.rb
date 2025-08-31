class AddColorHexToProductVariants < ActiveRecord::Migration[8.0]
  def change
    add_column :product_variants, :color_hex, :string
    add_index :product_variants, :color_hex
  end
end
