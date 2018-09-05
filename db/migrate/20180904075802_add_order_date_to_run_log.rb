class AddOrderDateToRunLog < ActiveRecord::Migration[5.0]
  def change
  	add_column :run_logs, :order_date, :datetime
  	add_column :run_logs, :invoice_date, :datetime
  end
end
