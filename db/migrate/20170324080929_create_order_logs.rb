class CreateOrderLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :order_logs do |t|
      t.string :magento_id
      t.string :qbo_id
      t.integer :last_runlog_id
      t.timestamps
    end
  end
end
