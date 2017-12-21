class AddOrderAmountToRunLog < ActiveRecord::Migration[5.0]
  def change
    add_column :run_logs, :order_amount, :decimal, default: 0
  end
end
