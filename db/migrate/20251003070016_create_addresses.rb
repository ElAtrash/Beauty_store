class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :label, null: false, default: "Home"
      t.string :address_line_1, null: false
      t.string :address_line_2
      t.string :city, null: false
      t.string :governorate, null: false
      t.string :landmarks
      t.string :phone_number
      t.boolean :default, default: false, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    # Index for finding default address per user efficiently
    add_index :addresses, [ :user_id, :default ], name: "index_addresses_on_user_id_and_default"

    # Index for soft deletes
    add_index :addresses, :deleted_at

    # Ensure label uniqueness per user (excluding deleted)
    add_index :addresses, [ :user_id, :label ],
              unique: true,
              where: "deleted_at IS NULL",
              name: "index_addresses_on_user_id_and_label_active"
  end
end
