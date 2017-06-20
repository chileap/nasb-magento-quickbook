class AddInvoiceIdToOrderLog < ActiveRecord::Migration[5.0]
  def change
    if !OrderLog.first.attributes.keys.include?("invoice_id")
      add_column :order_logs, :invoice_id, :string
    end
  end
end
