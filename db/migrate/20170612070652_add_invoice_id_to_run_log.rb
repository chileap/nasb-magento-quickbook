class AddInvoiceIdToRunLog < ActiveRecord::Migration[5.0]
  def change
    if !RunLog.first.attributes.keys.include?("invoice_id")
      add_column :run_logs, :invoice_id, :string
    end
  end
end
