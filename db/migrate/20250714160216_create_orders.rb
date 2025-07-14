class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.string :number, null: false
      t.references :user, foreign_key: true
      t.string :email, null: false

      t.string :status, default: 'pending'
      t.string :payment_status, default: 'pending'
      t.string :fulfillment_status

      t.monetize :subtotal, default: 0
      t.monetize :tax_total, default: 0
      t.monetize :shipping_total, default: 0
      t.monetize :discount_total, default: 0
      t.monetize :total, default: 0

      t.jsonb :billing_address, default: {}
      t.jsonb :shipping_address, default: {}

      t.text :notes

      t.timestamps
    end

    add_index :orders, :number, unique: true
    add_index :orders, :status
  end
end
