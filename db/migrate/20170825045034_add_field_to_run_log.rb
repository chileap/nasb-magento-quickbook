class AddFieldToRunLog < ActiveRecord::Migration[5.0]
  def change
    add_column :run_logs, :credit_amount, :decimal
    add_column :run_logs, :order_status, :string
    add_column :run_logs, :billing_name, :string
  end
end
