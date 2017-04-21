class AddOrderIdToOrderLog < ActiveRecord::Migration[5.0]
  def change
    add_column :order_logs, :order_id, :string
  end
end
