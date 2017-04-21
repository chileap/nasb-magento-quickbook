class AddOrderIdToRunLog < ActiveRecord::Migration[5.0]
  def change
    add_column :run_logs, :order_id, :string
  end
end
