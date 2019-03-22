class AddValueToState < ActiveRecord::Migration[5.0]
  def change
    add_column :states, :value, :string
  end
end
