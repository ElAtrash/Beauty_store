class AddEcommerceFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :phone_number, :string
    add_column :users, :preferred_language, :string, default: 'ar'
    add_column :users, :governorate, :string
    add_column :users, :city, :string
    add_column :users, :date_of_birth, :date
    add_column :users, :admin, :boolean, default: false

    add_index :users, :phone_number
    add_index :users, :preferred_language
    add_index :users, :governorate
    add_index :users, :admin
  end
end
