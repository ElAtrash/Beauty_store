class CreateDiscounts < ActiveRecord::Migration[8.0]
  def change
    create_table :discounts do |t|
      t.string :code, null: false
      t.string :discount_type, null: false # percentage, fixed
      t.monetize :value
      t.integer :usage_limit
      t.integer :usage_count, default: 0, null: false
      t.datetime :valid_from
      t.datetime :valid_until
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :discounts, :code, unique: true
    add_index :discounts, [ :active, :valid_from, :valid_until ]
  end
end
