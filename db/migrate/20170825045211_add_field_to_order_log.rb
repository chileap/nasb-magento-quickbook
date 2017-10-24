class AddFieldToOrderLog < ActiveRecord::Migration[5.0]
  def change
    add_column :order_logs, :credit_amount, :decimal
    add_column :order_logs, :order_status, :string
    add_column :order_logs, :billing_name, :string
  end
end
