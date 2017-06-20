class AddTypeToOrderLog < ActiveRecord::Migration[5.0]
  def change
    add_column :order_logs, :run_type, :string, :default => 'sale_receipt'
  end
end
