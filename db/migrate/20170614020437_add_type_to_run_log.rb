class AddTypeToRunLog < ActiveRecord::Migration[5.0]
  def change
    add_column :run_logs, :run_type, :string, :default => 'sale_receipt'
  end
end
