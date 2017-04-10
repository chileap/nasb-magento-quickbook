class CreateRuns < ActiveRecord::Migration[5.0]
  def change
    create_table :runs do |t|
      t.datetime :run_date

      t.timestamps
    end
  end
end
