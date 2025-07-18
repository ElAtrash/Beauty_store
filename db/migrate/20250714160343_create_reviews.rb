class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :rating, null: false
      t.string :title
      t.text :body
      t.boolean :verified_purchase, default: false, null: false
      t.string :status, default: 'pending'

      t.timestamps
    end

    add_index :reviews, [ :product_id, :status ]
    add_index :reviews, :rating
    add_check_constraint :reviews, 'rating >= 1 AND rating <= 5', name: 'rating_range'
  end
end
