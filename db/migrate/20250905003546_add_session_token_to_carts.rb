class AddSessionTokenToCarts < ActiveRecord::Migration[8.0]
  def change
    add_column :carts, :session_token, :string, null: false, limit: 32
    add_index :carts, :session_token, unique: true
  end
end
