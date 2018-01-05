class CreateSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :settings do |t|
      t.string :magento_tax_code
      t.string :qbo_tax_code

      t.timestamps
    end
  end
end
