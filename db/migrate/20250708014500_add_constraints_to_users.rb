class AddConstraintsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_check_constraint :users, "first_name IS NULL OR length(first_name) >= 2", name: "first_name_min_length"
    add_check_constraint :users, "last_name IS NULL OR length(last_name) >= 2", name: "last_name_min_length"
    add_check_constraint :users, "date_of_birth IS NULL OR date_of_birth < CURRENT_DATE", name: "date_of_birth_in_past"
    add_check_constraint :users, "preferred_language IS NULL OR preferred_language IN ('ar', 'en')", name: "valid_language"

    # Add index for common queries
    add_index :users, [ :governorate, :city ]
    add_index :users, :date_of_birth
    add_index :users, [ :admin, :created_at ]
  end
end
