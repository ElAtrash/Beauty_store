class MakeAddressLabelOptional < ActiveRecord::Migration[8.0]
  def change
    # Remove default value from label column
    change_column_default :addresses, :label, from: "Home", to: nil

    # Allow NULL values for label
    change_column_null :addresses, :label, true
  end
end
