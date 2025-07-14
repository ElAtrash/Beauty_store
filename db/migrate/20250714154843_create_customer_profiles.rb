class CreateCustomerProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :skin_type
      t.text :skin_concerns, array: true, default: []
      t.jsonb :tags, default: []
      t.monetize :total_spent, default: 0

      t.timestamps
    end
  end
end
