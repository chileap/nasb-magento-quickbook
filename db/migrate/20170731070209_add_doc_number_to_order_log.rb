class AddDocNumberToOrderLog < ActiveRecord::Migration[5.0]
  def change
    add_column :run_logs, :doc_number, :string
  end
end
