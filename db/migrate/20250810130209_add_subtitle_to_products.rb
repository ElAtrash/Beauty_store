class AddSubtitleToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :subtitle, :string
  end
end
