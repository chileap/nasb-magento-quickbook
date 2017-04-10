class CreateRecordTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :record_tokens do |t|
      t.string :access_token
      t.string :access_secret
      t.string :company_id
      t.datetime :token_expires_at
      t.string :type_token
      t.timestamps
    end
  end
end
