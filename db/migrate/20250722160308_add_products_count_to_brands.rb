class AddProductsCountToBrands < ActiveRecord::Migration[8.0]
  def change
    add_column :brands, :products_count, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        Brand.find_each do |brand|
          Brand.reset_counters(brand.id, :products)
        end
      end
    end
  end
end
