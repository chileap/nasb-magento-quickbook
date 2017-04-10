class CreateRunLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :run_logs do |t|
      t.string :magento_id
      t.string :qbo_id
      t.string :status
      t.string :message
      t.references :run
      t.timestamps
    end
  end
end
